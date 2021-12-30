from dataclasses import dataclass, field


@dataclass
class Component:

    name: str
    parent: str = field(default='general', metadata={'version': 'latest'})
    child: str = field(default='general', metadata={'version': 'latest'})
    description: str = field(default='')
    language: str = field(default='', metadata={'version': 'latest'})
    package: str = field(default='')
    method:  str = field(default='')


def get_components():
    return [

        Component(name='demo_demo_py',
                  parent='demo',
                  child='demo',
                  description='Demonstration of calling a Python function.',
                  language='Python',
                  package='im3components.demo.py_demo',
                  method='py_demo'),

        Component(name='demo_demo_r',
                  parent='demo',
                  child='demo',
                  description='Demonstration of calling an R function from Python.',
                  language='R',
                  package='im3components.demo.r_demo',
                  method='r_demo'),

        Component(name='population_tell_counties',
                  parent='Population',
                  child='TELL',
                  description='Aggregate (sum) gridded population data to counties.',
                  language='Python',
                  package='im3components.pop_tell_counties',
                  method='population_to_tell_counties'),

        Component(name='wrf_to_tell_counties',
                  parent='WRF',
                  child='TELL',
                  description='Convert gridded WRF data to mean county data.',
                  language='Python',
                  package='im3components.wrf_tell.wrf_tell_counties',
                  method='wrf_to_tell_counties'),

        Component(name='wrf_to_tell_balancing_authorities',
                  parent='WRF',
                  child='TELL',
                  description='Convert mean county data to mean balancing authority data.',
                  language='Python',
                  package='im3components.wrf_tell.wrf_tell_balancing_authorities',
                  method='wrf_to_tell_balancing_authorities'),

    ]

if __name__ == '__main__':

    l = get_components()

