from dataclasses import dataclass, field
from enum import Enum
import importlib
import pkg_resources
import r_functions as rfn
from typing import List
from yaml import load
try:
    from yaml import CLoader as Loader
except ImportError:
    from yaml import Loader

from im3components.taxonomy import Component


class AssetType(Enum):
    Experiment = 'Experiment'
    Model = 'Model'
    Component = 'Component'
    DataSet = 'DataSet'


def load_from_yaml(asset_type: AssetType):
    base_path = f'data/taxonomy/{asset_type.value.casefold()}'
    assets = []
    if asset_type:
        resources = pkg_resources.resource_listdir('im3components', base_path)
        for resource in resources:
            resource_string = pkg_resources.resource_string('im3components', f'{base_path}/{resource}')
            assets.append(
                load(
                    f"!!python/object:im3components.taxonomy.{asset_type.value}\n{resource_string.decode('utf-8')}",
                    Loader=Loader
                )
            )
    return assets


@dataclass
class Registry:

    components: List[Component] = field(default_factory=lambda: load_from_yaml(AssetType.Component))

    def list_related(self, asset: str) -> list:
        """List all components that are related to the target asset.

        :param asset:                name of the asset
        :type asset:                 str

        """

        return [c.name for c in self.components if c.is_related(asset)]

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
    return Registry()
