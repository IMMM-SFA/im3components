import pkg_resources
from dataclasses import dataclass, field

import r_functions as rfn

from im3components.gcam_cerf_expansion_plan import gcam_cerf_expansion
from im3components.wrf_tell.wrf_tell_counties import wrf_to_tell_counties
from im3components.pop_tell_counties import population_to_tell_counties



@dataclass
class Component:

    name: str
    parent: str = field(default='general', metadata={'version': 'latest'})
    child: str = field(default='general', metadata={'version': 'latest'})
    description: str = field(default='')
    language: str = field(default='', metadata={'version': 'latest'})
    code: object = field(default=object)


def get_components():
    return [

        Component(name='demo_demo_r',
                  parent='demo',
                  child='demo',
                  description='Demonstration of calling an R function from Python.',
                  language='R',
                  code=rfn.create(pkg_resources.resource_filename('im3components', 'r/r_demo.R'), 'r_demo')),

        Component(name='population_tell_counties',
                  parent='Population',
                  child='TELL',
                  description='Aggregate (sum) gridded population data to counties.',
                  language='Python',
                  code=population_to_tell_counties),

        Component(name='wrf_tell_counties',
                  parent='WRF',
                  child='TELL',
                  description='Convert gridded WRF data to mean county data.',
                  language='Python',
                  code=wrf_to_tell_counties),

        Component(name='gcam_cerf_expansion',
                  parent='GCAM',
                  child='CERF',
                  description='Convert GCAM outputs to cerf inputs for the expansion plan.',
                  language='Python',
                  code=gcam_cerf_expansion)
    ]

