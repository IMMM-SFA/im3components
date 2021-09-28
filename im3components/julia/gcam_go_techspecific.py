import pkg_resources

from julia.api import Julia
from julia import Main


jl = Julia(compiled_modules=False)


def gcam_go_techspecific(x, y):

    pass

julia_file = pkg_resources.resource_filename('im3components', 'julia', 'gcam_go_techspecific.jl')

jl.eval(f'include("{julia_file}"')
Main.x = 1
Main.y = 2
output = jl.eval(f"gcam_go_techspecific(x, y)")
print(output)