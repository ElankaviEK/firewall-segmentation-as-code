"""A "smoke test": the simplest possible test.

It only checks that our package can be imported.
If this fails, the project setup itself is broken.
"""

import fwseg


def test_package_imports():
    # If 'import fwseg' above worked, the package exists.
    # We also check that the main() function is there.
    assert hasattr(fwseg, "main")
