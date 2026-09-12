{
  # Remove keys managed by the previous generation before merging the current
  # declaration. Unmanaged runtime state is left intact.
  jqMergeFilter = ''
    def remove_managed($mask):
      if type == "object" and ($mask | type) == "object" then
        reduce ($mask | keys[]) as $key (.;
          if (.[$key] | type) == "object" and ($mask[$key] | type) == "object" then
            .[$key] |= remove_managed($mask[$key])
            | if .[$key] == {} then del(.[$key]) else . end
          else
            del(.[$key])
          end
        )
      else
        .
      end;
    remove_managed($previous[0]) * $declared[0]
  '';
}
