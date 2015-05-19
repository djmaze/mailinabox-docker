function hide_output {
  # This function hides the output of a command unless the command fails
  # and returns a non-zero exit code.

  # Get a temporary file.
  OUTPUT=$(tempfile)

  # Execute command, redirecting stderr/stdout to the temporary file.
  $@ &> $OUTPUT

  # If the command failed, show the output that was captured in the temporary file.
  E=$?
  if [ $E != 0 ]; then
    # Something failed.
    echo
    echo FAILED: $@
    echo -----------------------------------------
    cat $OUTPUT
    echo -----------------------------------------
    exit $E
  fi

  # Remove temporary file.
  rm -f $OUTPUT
}
