This project is a test harness for JVM memory parameters on Cloud
Foundry. It pushes sample apps to Cloud Foundry and then hits them
with a few requests to the home page. Each push is parameterized with
various inputs like the container memory limit and various JVM memory
options, and the result is recorded as an overall status (ideally
"running"), plus the number of failed requests (ideally 0).

> NOTE: The prequisites for running the build are Java (8) and Apache
> Bench on your path, plus the `cf` command line client and some
> standard UN*X tools like grep and awk. You must be authenticated
> against your chosen Cloud Foundry platform before you start.

The `Makefile` has a default target (`all`) which reads inputs from a
file `input.txt`, and runs `push.sh` once per line, appending results
to `build/result.txt`. I.e. the best way to run the whole suite is:

```
$ make
```

and then look at the results in `build`. There shoudl be a file there
called `result.txt` in this format:

```
id app type limit status errors
manfb freemarker boot 128 crashed 0
manfbm freemarker boot 128 running 0
...
```

The "status" is the status reported by `cf app` after it was pushed
(success is "running"), and the "errors" is a count of errors out of
100 HTTP requests to the home page of the app, assuming the status was
"running".

Historic results have been copied manually (along with the inputs) to
the `results` directory.

## Sample Applications

There are a couple of sample apps in subdirectories:

* *freemarker*: the freemarker sample from Spring Boot
* *zuul*: a basic reverse proxy with Spring Cloud
* *ratpack*: a "Hello World" Spring Boot Ratpack app
* *dispatcher*: a "Hello World" Spring Boot Reactive app with RxNetty

Every sample can be built on the command line either with nested jars
(standard Spring Boot tooling) or shaded. E.g.

```
$ cd freemarker
$ mvn package -P boot,!shaded
```

(these are the default settings). You can build a shaded version using
the "shaded" profile and a standard Boot jar using the "boot" profile.

There is a `Makefile` that is used to drive the automation. Each
sample app has a target that builds its jar files and stores them
under `build/{type}`:

```
$ make freemarker
...
$ find build
build/boot/freemarker.jar
build/shaded/freemarker.jar
``

### Adding a New Sample

If you add a new app it will be included automatically in the build
(by detecting the `pom.xml` in the `Makefile`). Make sure it has the
same build structure (i.e. 2 profiles, "boot" and "shaded") and the
artifact ID starts with "sample".

## The Driver Script

Once the jar files are built, the main workhorse is a script `push.sh`
which takes aguments in the form:

|Name   | Description | Example |
|-------|-------------|---------|
|id     |An identifier for this experiment       |ssfb128|
|app    |The sample app name (a subdirectory)    |freemarker |
|type   |The jar type (shaded or boot)           |boot   |
|limit  |The memory limit (in MB)                |256    |
|mx     |The max heap size (in MB)               |162    |
|ms     |The initial heap size (in MB)           |100    |
|ss     |The stack size (in KB)                  |256    |
|maxmeta|The max metaspace size (in MB)          |168    |
|meta   |The initial metaspace size (in MB)      |20     |
|ccss   |The CompressedClassSpaceSize (in MB)    |8      |
|rccs   |The ReservedCodeCacheSize (in MB)       |4      |
|main   |The main type to use (can be empty or "auto"). If provided then corresponds to a manifest entry name (case insensitive). |start-class |
|extra  |Additional JVM command line options     |-verbose:class |

Example:

```
$ ./push.sh ssfb256  freemarker boot   256  74  32  366  80  20 8 4
```

runs the freemarker sample as a boot app with a command line with these options:

```
$ -Xmx74M -Xms32M -Xss366K -XX:MaxMetaspaceSize=80M -XX:MetaspaceSize=20M -XX:CompressedClassSpaceSize=8M -XX:ReservedCodeCacheSize=4M
```

You can manually do the same thing as the build, once the jar files
are prepared, like this (with a custom input file):

```
$ cat myinputs.txt | xargs -L 1 ./push.sh
```

