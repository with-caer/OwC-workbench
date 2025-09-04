Tools for managing single-user development environments (_"workbenches"_)
hosted on local workstations, cloud virtual machines, or [Dev Containers](https://containers.dev).

> _Note_: OwC tools are intended for use with Fedora or Rocky Linux hosts.

## Getting Started

The easiest way to get started is with a Dev Container:

``` json
{
    "image": "ghcr.io/with-caer/owc/workbench:latest"
}
```

This container comes preinstalled with all of the [workbench tools](tools/),
and can be extended with any of the [workbench features](features/).

### ...on `localhost`

Alternatively, [`instal-local.sh`](install-local.sh) can be run directly on any
machine running  Fedora or  Rocky Linux to configure that machine as a workbench.

## License and Contributions 

Media assets (logos, imagery, etc.) are Copyright With Caer, LLC, all rights reserved.

Code and documentation are Copyright With Caer, LLC, and licensed under
[the MIT license](https://github.com/with-caer/owc/blob/main/LICENSE.txt).