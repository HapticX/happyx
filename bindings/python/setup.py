"""
Provides setup script
"""
from os import path, makedirs
from setuptools import setup, find_packages, version

import happyxpy.happyx as happyx


# Load readme
with open('README.md', 'r', encoding='utf-8') as file:
    long_description = file.read()


setup(
    name='happyxpy',
    description='HappyX web framework bindings for Python 🐍',
    long_description=long_description,
    long_description_content_type='text/markdown',
    author='Ethosa',
    author_email='social.ethosa@gmail.com',
    maintainer='HapticX',
    maintainer_email='hapticx.company@gmail.com',
    url='https://github.com/HapticX/happyx/tree/master/bindings/python',
    version=happyx.happyx_version(),
    packages=find_packages(),
    include_package_data=True,
    install_requires=['jinja2'],
    py_modules=['happyx'],
    license='MIT',
    classifiers=[
        'Development Status :: 5 - Production/Stable',
        'Topic :: Software Development :: Libraries :: Application Frameworks',
        'License :: OSI Approved :: MIT License',
        'Operating System :: OS Independent',
        'Programming Language :: Python :: 3.7',
        'Programming Language :: Python :: 3.8',
        'Programming Language :: Python :: 3.9',
        'Programming Language :: Python :: 3.10',
        'Programming Language :: Python :: 3.11',
        'Programming Language :: Python :: 3.12',
    ]
)
