import os
import pathlib
import socket
import struct
import subprocess
import sys
import tempfile

helper, fixture, module, permit = sys.argv[1:]
with tempfile.TemporaryDirectory() as temp:
    root = pathlib.Path(temp)
    def configure(name, unlock, fail_update=False):
        (root / name).write_text(
            f"auth required {fixture}\n"
            f"auth optional {module}{' unlock' if unlock else ''}\n"
            f"session required {permit}\n"
            f"session optional {module}\n"
            f"password requisite {fixture}{' fail-update' if fail_update else ''}\n"
            f"password optional {module}\n"
        )
    configure("login-test", False)
    configure("lock-test", True)
    configure("password-test", False)
    configure("failed-password-test", False, fail_update=True)
    for name, mode in [("login-test", "session"), ("lock-test", "auth-only"), ("password-test", "password")]:
        path = root / f"{name}.sock"
        with socket.socket(socket.AF_UNIX) as server:
            server.bind(str(path))
            server.listen(1)
            server.settimeout(5)
            env = os.environ | {"OO7_PAM_SOCKET": str(path)}
            # The caller exits immediately after pam_end; delivery must survive it.
            subprocess.run([helper, name, str(root), mode], env=env, check=True, timeout=10)
            with server.accept()[0] as connection:
                connection.settimeout(5)
                def read_exact(size):
                    value = bytearray()
                    while len(value) < size:
                        part = connection.recv(size - len(value))
                        assert part, "PAM returned before delivering the complete request"
                        value.extend(part)
                    return value
                length, = struct.unpack("<I", read_exact(4))
                payload = read_exact(length)
                if mode == "password":
                    assert payload[0] == 1
                    assert b"osa-old-test-password" in payload
                    assert b"osa-new-test-password" in payload
                else:
                    assert payload[0] == 0
                    assert b"osa-pam-test-password" in payload
    # An unavailable keyring must not reject a valid login or screen unlock.
    for name, mode in [("login-test", "session"), ("lock-test", "auth-only")]:
        subprocess.run(
            [helper, name, str(root), mode],
            env=os.environ | {"OO7_PAM_SOCKET": str(root / "missing.sock")},
            check=True, timeout=10,
        )
    # A rejected system password change must not send a keyring update.
    path = root / "failed-password.sock"
    with socket.socket(socket.AF_UNIX) as server:
        server.bind(str(path))
        server.listen(1)
        server.settimeout(0.2)
        result = subprocess.run(
            [helper, "failed-password-test", str(root), "password"],
            env=os.environ | {"OO7_PAM_SOCKET": str(path)}, timeout=10,
        )
        assert result.returncode != 0
        try:
            server.accept()
        except TimeoutError:
            pass
        else:
            raise AssertionError("Rejected password change reached the keyring")
print("PAM login, lock, password-change, and unavailable-keyring tests passed")
