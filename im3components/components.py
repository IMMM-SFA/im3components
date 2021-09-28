from dataclasses import dataclass, field

from im3components.gcam_cerf_expansion_plan import gcam_cerf_expansion


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

        Component(name='wrf_tell_tocounty',
                  parent='WRF',
                  child='TELL',
                  description='Convert gridded WRF data to mean county data.',
                  language='Python',
                  code=gcam_cerf_expansion),

        Component(name='gcam_cerf_expansion',
                  parent='GCAM',
                  child='CERF',
                  description='Convert GCAM outputs to cerf inputs for the expansion plan.',
                  language='Python',
                  code=gcam_cerf_expansion)
    ]

