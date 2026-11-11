#include <security/pam_appl.h>
#include <security/pam_modules.h>
#include <pwd.h>
#include <signal.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

#ifdef FIXTURE
PAM_EXTERN int pam_sm_authenticate(pam_handle_t *pamh, int flags, int argc,
                                   const char **argv) {
    return pam_set_item(pamh, PAM_AUTHTOK, "osa-pam-test-password");
}
PAM_EXTERN int pam_sm_chauthtok(pam_handle_t *pamh, int flags, int argc,
                               const char **argv) {
    if (flags & PAM_PRELIM_CHECK)
        return pam_set_item(pamh, PAM_OLDAUTHTOK, "osa-old-test-password");
    if (argc > 0 && strcmp(argv[0], "fail-update") == 0) return PAM_AUTHTOK_ERR;
    return pam_set_item(pamh, PAM_AUTHTOK, "osa-new-test-password");
}
#else
static int conversation(int n, const struct pam_message **msg,
                        struct pam_response **response, void *data) {
    return PAM_CONV_ERR;
}
int main(int argc, char **argv) {
    struct passwd *account = getpwuid(getuid());
    if (argc != 4 || !account) return 2;
    struct pam_conv conv = {conversation, NULL};
    pam_handle_t *pamh = NULL;
    signal(SIGCHLD, SIG_IGN);
    int result = pam_start_confdir(argv[1], account->pw_name, &conv, argv[2], &pamh);
    if (result == PAM_SUCCESS) result = pam_authenticate(pamh, 0);
    if (result == PAM_SUCCESS && strcmp(argv[3], "session") == 0)
        result = pam_open_session(pamh, 0);
    if (result == PAM_SUCCESS && strcmp(argv[3], "password") == 0)
        result = pam_chauthtok(pamh, 0);
    if (result != PAM_SUCCESS)
        fprintf(stderr, "PAM fixture failed: %s\n", pam_strerror(pamh, result));
    if (pamh) pam_end(pamh, result);
    return result == PAM_SUCCESS ? 0 : 1;
}
#endif
