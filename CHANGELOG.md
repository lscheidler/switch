0.2.4 (2020-06-17)
==================

- aws alb: support dryrun (do not deregister and register to alb, if in dryrun mode)

0.2.3 (2020-06-16)
==================

- add --prefetch argument for prefetching artifacts without switching.

0.2.2 (2020-05-29)
==================

- added -i, --info argument to return information about current version
  as json
- print warnings to stderr

0.2.1 (2020-05-26)
==================

- added plugin for aws alb deregistration and registration

0.2.0 (2019-10-25)
==================

- added plugins for docker and ecr
- introduced "::before" and "::after" keywords for plugins
- added deployment mode
- support for /etc/default/<application>.switch.json config files, so we
  can set mode and type application specific (is going to replace
  /usr/local/bin/<application> -i TYPE)

0.1.0 (2019-03-01)
==================

- Initial release
