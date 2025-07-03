<!-- markdownlint-configure-file { "MD013": { "line_length": 300 } } -->

# Introduction

## Preface

The LFS book is an excellent resource to build your own Linux,
and it's more than enough to do it.
I'm doing is distilling the book into a slightly more succinct guide.
This means removing information, hopefully not critical one.
That being said, I can only do so much, so I still recommend you follow the LFS and
skim through the resources and insights it provides.

I've also had to adapt certain steps since I'm writing this guide with the purpose of
completing the `ft_linux` 42 project.
Mainly, using a different kernel version (4.9) instead of the latest current one.

**Very important notice**: Don't be like me and start to build the system following
the latest guide, and then a quarter of the way through figure out that you need to
use an older kernel, then try to fix it by just installing an older kernel and
following the rest of the **new** guide, then have to patch multiple packages,
downgrading some or modifying commands.
What I'm trying to say is do your research and probably follow the latest version
of the guide that uses a kernel version 4.x.

## How to build an LFS system

The LFS will be built on an existing Linux distro, that could be Fedora, openSUSe or any
other of your choice. I decided to use Debian. This will provide the necessary tools to gets
us started with the compilation of the tools.
