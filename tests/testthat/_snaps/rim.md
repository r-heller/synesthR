# .check_tool aborts cleanly for an absent tool

    Code
      .check_tool("definitely_not_a_real_binary_xyz")
    Condition
      Error:
      ! Required command-line tool "definitely_not_a_real_binary_xyz" was not found on the `PATH`.
      i This is optional; the core synesthR workflow does not need it.

# .check_pymod aborts when reticulate is absent

    Code
      .check_pymod("numpy")
    Condition
      Error:
      ! Python interop requires the reticulate package.
      i Install it with `install.packages("reticulate")`.
      i This is optional; the core synesthR workflow does not need it.

# .check_client validates package presence and probe

    Code
      .check_client("a_package_that_does_not_exist_xyz")
    Condition
      Error:
      ! This feature requires the a_package_that_does_not_exist_xyz package.
      i Install it with `install.packages("a_package_that_does_not_exist_xyz")`.
      i This is optional; the core synesthR workflow does not need it.

