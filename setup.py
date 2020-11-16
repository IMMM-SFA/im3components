from setuptools import setup, find_packages


def readme():
    with open('README.md') as f:
        return f.read()


def get_requirements():
    with open('requirements.txt') as f:
        return f.read().split()


setup(
    name='im3components',
    version='0.1.0',
    packages=find_packages(),
    url='https://github.com/IMMM-SFA/im3components',
    license='BSD 2-Clause',
    author='Chris R. Vernon',
    author_email='chris.vernon@pnnl.gov',
    description='IM3 components to maintain reproducible interoperability',
    python_requires='>=3.6.*',
    long_description=readme(),
    install_requires=get_requirements()
)
