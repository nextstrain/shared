"""
Shared functions to be used within a Snakemake workflow for parsing
workflow configs.
"""
import os.path
from collections.abc import Callable
from snakemake.io import Wildcards


class InvalidConfigError(Exception):
    pass


def resolve_config_path(path: str) -> Callable[[Wildcards], str]:
    """
    Resolve a relative *path* given in a configuration value.

    Resolves *path* as relative to the workflow's ``defaults/`` directory (i.e.
    ``os.path.join(workflow.basedir, "defaults", path)``) if it doesn't exist
    in the workflow's analysis directory (i.e. the current working
    directory, or workdir, usually given by ``--directory`` (``-d``)).

    This behaviour allows a default configuration value to point to a default
    auxiliary file while also letting the file used be overridden either by
    setting an alternate file path in the configuration or by creating a file
    with the conventional name in the workflow's analysis directory.

    Will always try to resolve *path* or the default path after expanding
    wildcards with Snakemake's `expand` functionality.
    """
    global workflow

    def _resolve_config_path(wildcards):
        expanded_path = expand(path, **wildcards)[0]
        if os.path.exists(expanded_path):
            return expanded_path

        # Special-case defaults/… for backwards compatibility with older
        # configs.  We could achieve the same behaviour with a symlink
        # (defaults/defaults → .) but that seems less clear.
        if path.startswith("defaults/"):
            defaults_path = os.path.join(workflow.basedir, path)
        else:
            defaults_path = os.path.join(workflow.basedir, "defaults", path)

        expanded_defaults_path = expand(defaults_path, **wildcards)[0]
        if os.path.exists(expanded_defaults_path):
            return expanded_defaults_path

        raise InvalidConfigError(f"""Unable to resolve config provided path.
        Checked for the following files:
        1. {expanded_path!r}
        2. {expanded_defaults_path!r}
        """)

    return _resolve_config_path
