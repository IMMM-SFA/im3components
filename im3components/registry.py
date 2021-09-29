from dataclasses import dataclass
from typing import List

from .components import Component, get_components


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

    def get_function(self, component_name):
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






def registry():
    """Instantiate registry class."""

    component_list = get_components()

    return Registry(component_list)
