import yaml


def read_yaml(yaml_file: str) -> dict:
    """Read a YAML file.

    :param yaml_file:               Full path with file name and extension to an input YAML file
    :type yaml_file:                str

    :return:                        Dictionary
    """

    with open(yaml_file, 'r') as yml:
        return yaml.load(yml, Loader=yaml.FullLoader)
