from dataclasses import dataclass
from typing import List
from rpy2.objects.packages import importr

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

        # list of class or function objects related to the target component name
        protocol = [i.code for i in self.components if i.name == component_name]

        # expected condition where there is one function
        if len(protocol) == 1:
            return protocol[0]

        elif len(protocol) == 0:
            msg = f"Component name '{component_name}' does not match any in the current registry."
            raise KeyError(msg)

        else:
            msg = f"There are duplicate entries for the name '{component_name} which is not allowed."
            raise AttributeError(msg)

    def metadata(self):
        """Report component metadata for the target."""

        pass

    def help(self, component_name: str):
        """Generate help from docstring of component."""

        fn = self.get_component(component_name=component_name)

        base = importr('base')

        return help(fn)

    def run(self, component_name: str, *args, **kwargs):
        """Launch run of component."""

        fn = self.get_component(component_name=component_name)

        return fn(*args, **kwargs)


def registry():
    """Instantiate registry class."""

    component_list = get_components()

    return Registry(component_list)


if __name__ == '__main__':

    reg = registry()

    reg.help(component_name='demo_demo_py')

