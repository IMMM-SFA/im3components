import im3components as cmp


class BuildDocs:

    TargetFile = 'components.rst'

    def __init__(self):

        self.heading = """
==================
Component Registry
==================

"""

        self.body_element = """
{header_bar}
{name}
{header_bar}

**Parent**:        {parent}

**Child**:         {child}

**Description**:   {description}

**Language**:      {language}

"""

    def update_docs(self):

        with open(BuildDocs.TargetFile, 'w') as dest:

            # write RST header
            dest.write(self.heading)

            # instantiate the component registry
            reg = cmp.registry()

            # write component metadata to the RST file
            for i in reg.components:
                dest.write(self.body_element.format(header_bar='-' * (len(i.name) + 1),
                                                    name=i.name,
                                                    parent=i.parent,
                                                    child=i.child,
                                                    description=i.description,
                                                    language=i.language))


def update_component_docs():
    """Update the components.rst file with currently implemented components."""

    BuildDocs().update_docs()
