import pkg_resources
from typing import List
from dataclasses import dataclass

import importlib
import r_functions as rfn

from im3components.components import Component, get_components


@dataclass
class Registry:

    components: List[Component]

    def list_related(self, asset: str) -> list:
        """List all components that are related to the target asset.

        :param asset:                name of the asset
        :type asset:                 str

        """

        asset_lwr = asset.casefold()

        return [i.name for i in self.components if asset_lwr == i.parent.casefold() or asset_lwr == i.child.casefold()]

    def list_registry(self) -> list:
        """Return a list of all registered components."""

        return [i.name for i in self.components]

    def get_component(self, component_name: str):
        """Return a component function by its name."""

        # dict of class or function objects related to the target component name
        protocol = [[i.package.strip(), i.method.strip(), i.language.strip()] for i in self.components if i.name == component_name]

        # expected condition where there is one function
        if len(protocol) == 1:
            package, method, language = protocol[0]

            # if using R
            if language.casefold() == 'r':

                # split package name out of object oriented spec to use r_functions call
                package_split = package.split('.')
                package_path = '/'.join(package_split[1:])
                file_path = pkg_resources.resource_filename(package_split[0], f'{package_path}.R')

                return rfn.create(file_path, method)

            # if Python
            else:
                return getattr(importlib.import_module(package), method)

        elif len(protocol) == 0:
            msg = f"Component name '{component_name}' does not match any in the current registry."
            raise KeyError(msg)

        else:
            msg = f"There are duplicate entries for the name '{component_name} which is not allowed."
            raise AttributeError(msg)

    def metadata(self):
        """Report component metadata for the target."""

        pass

    # TODO:  setup help call on R functions
    def help(self, component_name: str):
        """Generate help from docstring of component."""

        fn = self.get_component(component_name=component_name)

        return help(fn)

    def run(self, component_name: str, *args, **kwargs):
        """Launch run of component."""

        fn = self.get_component(component_name=component_name)

        return fn(*args, **kwargs)


def registry():
    """Instantiate registry class."""

    component_list = get_components()

    return Registry(component_list)
