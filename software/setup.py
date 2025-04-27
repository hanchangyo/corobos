from setuptools import setup, find_packages

setup(
    name='toio-control-python',
    version='0.1',
    packages=find_packages(),
    install_requires=[
        'bleak',
        'asyncio',
        'python-osc'
    ],
)
