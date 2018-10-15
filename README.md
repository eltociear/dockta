> This is a work in progress

> 🔧 Wrench emoji are for README to do items. We'll remove any of these that are remaining into Github issues prior to releasing.

> 🔧 Add logo (something with a whale and a doctor?)

# Dockter : a Docker image builder for researchers

[![Docs](https://img.shields.io/badge/docs-API-blue.svg)](https://stencila.github.io/dockter/)
[![NPM](http://img.shields.io/npm/v/@stencila/dockter.svg?style=flat)](https://www.npmjs.com/package/@stencila/dockter)
[![Build status](https://travis-ci.org/stencila/dockter.svg?branch=master)](https://travis-ci.org/stencila/dockter)
[![Code coverage](https://codecov.io/gh/stencila/dockter/branch/master/graph/badge.svg)](https://codecov.io/gh/stencila/dockter)
[![Dependency status](https://david-dm.org/stencila/dockter.svg)](https://david-dm.org/stencila/dockter)
[![Chat](https://badges.gitter.im/stencila/stencila.svg)](https://gitter.im/stencila/stencila)

Docker is a good tool for creating reproducible computing environments. But creating truely reproducible Docker images can be difficult. Dockter aims to make it easier for researchers to create Docker images for their research projects. Dockter automatically creates and manages a Docker image for _your_ project based on _your_ source source code.

> 🔧 Add a GIF of a console session similar to [this one](http://media.kennethreitz.com.s3.amazonaws.com/pipenv.gif) by Kenneth Reitz for Pipenv

> 🦄 Features that are not yet implemented are indicated by unicorn emoji. Usually they have a link, like this [#2](https://github.com/stencila/dockter/issues/2), indicating the relevent issue where you can contribute to make the feature happen. It's [readme driven development](http://tom.preston-werner.com/2010/08/23/readme-driven-development.html) with calls to action to chase after mythical vaporware creatures! So hip.

<!-- Automatically generated TOC. Don't edit, `make docs` instead>

<!-- toc -->

- [Features](#features)
  * [Automatically builds a Docker image for your project](#automatically-builds-a-docker-image-for-your-project)
    + [R](#r)
    + [Python](#python)
    + [Node.js](#nodejs)
    + [Jupyter](#jupyter)
  * [Efficiently handling of updates to project code](#efficiently-handling-of-updates-to-project-code)
  * [Generates structured meta-data for your project](#generates-structured-meta-data-for-your-project)
- [Install](#install)
  * [CLI](#cli)
  * [Package](#package)
- [Use](#use)
  * [CLI](#cli-1)
    + [Compiling an environment](#compiling-an-environment)
    + [Executing an environment](#executing-an-environment)
  * [Router and server](#router-and-server)
- [Architecture](#architecture)
- [Develop](#develop)
- [See also](#see-also)
- [FAQ](#faq)
- [Acknowledgments](#acknowledgments)

<!-- tocstop -->

## Features

### Automatically builds a Docker image for your project

Dockter scans your project folder and builds a Docker image for it. If the the folder already has a Dockerfile, then Dockter will build the image from that. If not, Dockter will scan the files in the folder, generate a `.Dockerfile` and build the image from that. How Dockter builds the image from your source code depends on the language.

#### R

If the folder contains a R [`DESCRIPTION`](http://r-pkgs.had.co.nz/description.html) file then Docker will build an image with the R packages listed under `Imports` installed. e.g.

```
Package: myrproject
Version: 1.0.0
Date: 2017-10-01
Imports:
   ggplot2
```

The `Package` and `Version` fields are required in a `DESCRIPTION` file. The `Date` field is used to define which CRAN snapshot to use. MRAN daily snapshots began [2014-09-08](https://cran.microsoft.com/snapshot/2014-09-08) so the date should be on or after that.

If the folder does not contain a `DESCRIPTION` file then Dockter will 🦄 [#6](https://github.com/stencila/dockter/issues/6) scan all the folder's R files (files with the extension `.R` or `.Rmd`, or lowercase versions of those) for `library(package)` statements and create a `.DESCRIPTION` file for you.

#### Python

If the folder contains a 🦄 [#3](https://github.com/stencila/dockter/issues/3) [`requirements.txt`](https://pip.readthedocs.io/en/1.1/requirements.html) file, or a 🦄 [#4](https://github.com/stencila/dockter/issues/4) [`Pipfile`](https://github.com/pypa/pipfile), Dockter will copy it into the Docker image and use `pip` to install the specified packages.

If the folder does not contain either of those files then Dockter will 🦄 [#5](https://github.com/stencila/dockter/issues/5) scan all the folder's `.py` files for `import` statements and create a `.requirements.txt` file for you.

#### Node.js

If the folder contains a 🦄 [#7](https://github.com/stencila/dockter/issues/7) [`package.json`](https://docs.npmjs.com/files/package.json) file, Dockter will copy it into the Docker image and use `npm` to install the specified packages.

If the folder does not contain a `package.json` file, Dockter will 🦄 [#8](https://github.com/stencila/dockter/issues/8) scan all the folder's `.js` files for `import` or `require` statements and create a `.package.json` file for you.

#### Jupyter

If the folder contains any 🦄 [#9](https://github.com/stencila/dockter/issues/9) `.ipynb` files, Dockter will scan the code cells in those files for any Python `import` or R `library` statements and extract a list of package dependencies. It will also  🦄 [#10](https://github.com/stencila/dockter/issues/10) add Jupyter to the built Docker image.

### Efficiently handling of updates to project code

Docker layered filesystem has advantages but it can cause real delays when you are updating your project dependencies. For example, see [this issue](https://github.com/npm/npm/issues/11446) for the workarounds used by Node.js developers to prevent long waits when they update their `package.json`. The reason this happens is that when you update a requirements file Docker throws away all the susequent layers, including the one where you install all your package dependencies.

Here's a simple motivating [example](fixtures/tests/py-pandas) of a Dockerized Python project. It's got a [`pip`](https://pypi.org/project/pip/) `requirements.txt` file which specifies that the project requires `pandas` which, to ensure reproducibility, is pinned to version `0.23.0`,

```
pandas==0.23.0
```

The project has also got a `Dockerfile` that specifies which Python version we want, copies `requirements.txt` into the image, and installs the packages:

```Dockerfile
FROM python:3.7.0

COPY requirements.xt .
RUN pip install -r requirements.txt
```

You can build a Docker image for that project using Docker,

```bash
docker build .
```

Docker will download the base Python image (if you don't yet have it), and download five packages (`pandas` and it's four dependencies) and install them. This took over 9 minutes when we ran it.

Now, let's say that we want to do some plotting in our library, so we add `matplotlib` as a dependency in `requirements.txt`,

```
pandas==0.23.0
matplotlib==3.0.0
```

When we do `docker build .` again Docker notices that the `requirements.txt` file has changed and so throws away that layer and all subsequant ones. This means that it will download and install **all** the necesary packages again, including the ones that we previously installed - and takes longer than the first install. For a more contrieved illustration of this, simply add a space to a line in the `requirements.txt` file and notice how the package install gets repeated all over again.

Now, let's add a special `# dockter` comment to the Dockerfile before the `COPY` directive,

```Dockerfile
FROM python:3.7.0

# dockter

COPY requirements.xt .
RUN pip install -r requirements.txt
```

The comment is ignored by Docker but tells `dockter` to run all subsequent directives and commit them into a single layer,

```bash
dockter build .
```

> 🔧 Finish description of commit-based approach and illustrate speed up over normal Docker builds

### Generates structured meta-data for your project

Dockter has been built to expose a JSON-LD API so that it works with other tools. It will parse a Dockerfile into a JSON-LD [`SoftwareSourceCode`](https://schema.org/SoftwareSourceCode) node extracting meta-data about the Dockerfile and build it into a `SoftwareEnvironment` node with links to the source files and the build image.

> 🔧 Illustrate how this is done for all project sources including non Dockerfiles

> 🔧 Replace this JSON-LD with final version

```json
{
  "@context": "https://schema.stenci.la",
  "type": "SoftwareSourceCode",
  "id": "https://hub.docker.com/#sha256:27d6e441706e89dac442c69c3565fc261b9830dd313963cb5488ba418afa3d02",
  "author": [],
  "text": "FROM busybox\nLABEL description=\"Prints the current date and time at UTC, to the nearest second, in ISO-8601 format\" \\\n      author=\"Nokome Bentley <nokome@stenci.la>\"\nCMD date -u -Iseconds\n",
  "programmingLanguage": "Dockerfile",
  "messages": [],
  "description": "Prints the current date and time at UTC, to the nearest second, in ISO-8601 format"
}
```

## Install

Dockter is available as pre-compiled, standalone command line tool, or as an Node.js package.

### CLI

> 🔧 Add `pkg`-based binary builds
> 🔧 Add download instructions

### Package

> 🔧 Register package on NPM; add publishing and release commands to npm scripts and Makefile and travis.yml

```bash
npm install @stencila/dockter
```

You will need to [install Docker](https://docs.docker.com/install/) if you don't already have it on your system.

> 🔧 Allow for the use of a remote Docker daemon for building images

## Use

This package is primarily designed to be used a compiler service within a Stencila deployment (e.g. `stencila/cloud`). But you can also use it standalone via the API or command line interface. 

### CLI

The command line interface (CLI) is a good way to get an understanding of what this package does. Essentially, it just exposes the compiler API on the command line.

#### Compiling an environment

The most basic thing that this package does is to read a `Dockerfile`, parse it to extract metadata, build a Docker image for it, and run that image as a Docker container.

Here's a very simple example `Dockerfile`. It uses the tiny `busybox` image as a base, adds some meta-data about the image, and then specifies the command to run to print out the date.

```Dockerfile
FROM busybox
LABEL description="Returns the current date and time at UTC, to the nearest second, in ISO-8601 format" \
      author="Nokome Bentley <nokome@stenci.la>"
CMD date -u -Iseconds
```

You can use the `compile` command to a Dockerfile like this into a JSON-LD `SoftwareEnvironment` node,

```bash
dockter compile Dockerfile > environ.jsonld
```

```json
{
  "@context": "https://schema.stenci.la",
  "type": "SoftwareSourceCode",
  "id": "https://hub.docker.com/#sha256:27d6e441706e89dac442c69c3565fc261b9830dd313963cb5488ba418afa3d02",
  "author": [],
  "text": "FROM busybox\nLABEL description=\"Prints the current date and time at UTC, to the nearest second, in ISO-8601 format\" \\\n      author=\"Nokome Bentley <nokome@stenci.la>\"\nCMD date -u -Iseconds\n",
  "programmingLanguage": "Dockerfile",
  "messages": [],
  "description": "Prints the current date and time at UTC, to the nearest second, in ISO-8601 format"
}
```

> 🔧 Replace this JSON output when a more final version available.

The default CLI output format is JSON but you can get YAML, which is easier to read, by using the `--format=yaml` option. You can turn off building of the Docker image (to just extract meta-data) using `--build=false`. Use `dockter compile --help` for more help.


#### Executing an environment

```bash
dockter execute environ.jsonld
```

```bash
dockter execute Dockerfile
```

### Router and server

The [Express](https://expressjs.com) router provides `PUT /compile` and `PUT /execute` endpoints (which do the same thing as the corresponding CLI commands). You can serve them using,

```bash
npm start
```

Or, during development using,

```bash
npm run server
```

A minimal example of how to integrate the router into your own Express server,

```js
const app = require('express')()
const { docker } = require('@stencila/dockter')

const app = express()
app.use('/docker', docker)
app.listen(3000)
```

## Architecture

Dockter implements a compiler design pattern. Source files are _parsed_ into a `SoftwareEnvironment` instance (the equivalent of an AST (Abstract Syntax Tree) in other programming language compilers) which is then used to generate a `Dockerfile` which is then built into a Docker image.

The parser classes e.g. `PythonParser`, `RParser` scan for relevant source files and generate `SoftwareEnvironment` instances.
The generator classes e.g. `PythonGenerator`, `RGenerator` generates a `Dockerfile` for a given `SoftwareEnvironment`.
`DockerGenerator` is a super-generator which combines the other generators.
`DockerBuilder` class builds 
`DockerCompiler` links all of these together.

For example, if a folder has single file in it `code.py`, `PythonParser` will parse that file and create a `SoftwareEnvironment` instance, which `DockerGenerator` uses to generate a `Dockerfile`, which `DockerBuilder` uses to build a Docker image.

## Develop

We 💕 contributions! To get started,

```bash
git clone https://github.com/stencila/dockter
cd dockter
npm install
```

Then take a look at the docs ([online](https://stencila.github.io/dockter/) or inline) and start hacking! Please check that your changes pass linting and unit tests,

```bash
npm run lint # or, make lint
npm test # or, make text
```

Use `npm test -- <test file path>` to run a single test file

You can setup a Git pre-commit hook to perform these checks automatically before each commit using `make hooks`.

Check that any changes you've made are covered 🏅 by unit tests using,

```bash
npm run cover # or, make cover
open coverage/lcov-report/index.html
```

If you've been working on in-code documentation 🙏 you can check that by building and viewing the docs,

```bash
npm run docs # or, make docs
open docs/index.html
```

Linting, test coverage, package building, and documentation generation are done on each push on [Travis CI](https://travis-ci.org/stencila/dockter).

To run the CLI during development use, `npm run cli -- <args>` e.g.

```bash
npm run cli -- compile tests/fixtures/dockerfile-date/Dockerfile
```

This uses `ts-node` to compile and run Typescript on the fly so that you don't need to do a build step first.

## See also

Related Stencila packages include:

- 🦄 [`stencila/tunix`](https://github.com/stencila/tunix): compiles JSON-LD `SoftwareEnvironment` nodes to [NixOS](https://nixos.org/) environments
- 🦄 [`stencila/kubex`](https://github.com/stencila/kubex): executes JSON-LD `SoftwareEnvironment` nodes on [Kubernetes](https://kubernetes.io/) clusters

- [`alibaba/derrick`](https://github.com/alibaba/derrick)
- [`jupyter/repro2docker`](https://github.com/jupyter/repo2docker)
- [`Gueils/whales`](https://github.com/Gueils/whales)
- [`o2r-project/containerit`](https://github.com/o2r-project/containerit)
- [`openshift/source-to-image`](https://github.com/openshift/source-to-image)
- [`ViDA-NYU/reprozip`](https://github.com/ViDA-NYU/reprozip])

Dockter is similar to `repro2docker`, `containerit`, and `reprozip` in that it is aimed at researchers doing data analysis (and supports R) whereas most other tools are aimed at software developers (and don't support R). Dockter differs to these projects principally in that by default (but optionally) it installs the necessary Stencila language packages so that the image can talk to Stencila client interfaces an provide code execution services. Like `repro2docker` it allows for multi-language images but has the additional features of package dependency analysis of source code, managed builds and generated of image meta-data.

## FAQ

*Why is this a Node.js package?*

We've implemented this as a Node.js package for easier integration into Stencila's Node.js based desktop and cloud deployments.

## Acknowledgments

Dockter was inspired by similar tools for researchers including [`binder`](https://github.com/binder-project/binder) and [`repro2docker`](https://github.com/jupyter/repo2docker). It relies on [`dockerode`](https://www.npmjs.com/package/dockerode), [`docker-file-parser`](https://www.npmjs.com/package/docker-file-parser), and of course [Docker](https://www.docker.com/).
