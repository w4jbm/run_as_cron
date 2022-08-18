# run-as-cron
A simple tool that can help you test and debug issues with cron scripts.

## BACKGROUND

Using cron to run scripts is a handy way to automate routine tasks. A very common question that comes up is why doesn't a shell script that works fine when I test it from the command prompt work when it runs as a cron job?

I'm batting a thousand on the answer I've given to people asking that question lately. Almost always when this happens it is because the `$PATH` used to search for commands in the shell started by cron does not match the `$PATH` you have when you run something from the command line. Typically what happens is the script being run by cron can't find the command, so things get 'skipped' and don't work as expected.

If you set up the mail system, you will actually get notifications when errors like this happen along with enough information to help with debugging, but few people do this. A handy alternative is to be able to run a scrip just like it was cron kicking off the job. Sometimes people will use crontab to edit the table of cron jobs to do this, but this is an extra step that you have to remember to back out once things are working and just another chance for a typo to creap into things. You also have to wait what always seems like it MUST be more than a minute for your changes to run.

Out of this was born run-as-cron. This is not a new idea and there are several versions flating around (see the References towards the end). But I wanted something that had better step-by-step instructions and some flexibility that I didn't see in the examples I found after a quick search.

## INSTALLING

Create a local folder to store the cron environment details in:

`$ mkdir ~/.local/share/run-as-cron`

Create a tempoary cron job by using `crontab -e` and adding the following line to the bottom of crontab:

`* * * * * /usr/bin/env > ~/.local/share/run-as-cron/cron-env`

Once this successfully runs, you can either delete it or change it so it runs once a day. Running it daily will ensure the configuration information is kept fresh, although the cron environment should not change often (if ever). But to be on the safe side, I went back into `crontab -e` and editted the line so that it now runs at 1:15 AM each morning:

`15 1 * * * /usr/bin/env > ~/.local/share/run-as-cron/cron-env`

Now go to the directory where you keep your Software ocdr Programs. You can either download the file or, if you have git installed, create a clone:

`$ git clone https://github.com/w4jbm/run_as_cron/`

On my system, I have these file in the directory `~/Software/run_as_cron`. Now just make sure things are set up to execute and put a symbolic link in a directory on the search path so we can run this from anywhere:
```
$ chmod +x install.sh
$ ./install.sh
```
And things should be ready to go!

## RUNNING

So if you have a daily script, you should be able to test it and see exactly how it will run as a cron job. That will look something like this:

`run-as-cron ~/ShellScripts/daily.sh`

One important thing is that commands with white space MUST be contained in quotes. For example, if you want to see what shell is in use, you must type:

`run-as-cron 'echo $SHELL'`

It would be nice to be able to do this without the quotes (and maybe someone has an idea on how to do that). I tried replacing the $1 variable with $* to allow all of the command line to be passed on. This had several problems. One is that the value $SHELL in the above example would be replaced with the value of the shell the command prompt was being run from. Also, the entire set of arguments gets "quoted" so it looks for something like an `echo /bin/bash` command instead of the `echo` command with a `$SHELL` argument.

The bottom line on that was that having to use single quotes isn't that painful since this isn't something I use that often. When I am using it, I typically have an editor open and just use the command line history to re-execute the same test command over and over until I get things working.

## WHAT MAKES UP THE CRON ENVIRONMENT?
Once we have the cron environment file saved, we can take a look at what is in it and what some of the implications are. Here is an example:
```
HOME=/home/username
MAILTO=name@email.com
LOGNAME=username
PATH=/usr/bin:/bin
LANG=en_US.UTF-8
SHELL=/bin/sh
PWD=/home/username
```
The location of the home directory, user name, and such is fairly straight forward. There are, however, two key things that stand out. First, look at the value of the `$SHELL` being used. We can look at this from the command line also:
```
$ echo $SHELL
/bin/bash
$ run-as-cron 'echo $SHELL'
/bin/sh
$ 
```
While cron jobs make use of `sh`, the Bourne shell, the command line we typically are working with is using `bash`, the Bourne again shell. This is reasonable since things like command line completion and command history are great when we're at the keyboard, but shouldn't be needed by an automated scripe.

The difference that causes the most headaches is around the `$PATH`:
```
$ echo $PATH
/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games:/sbin:/usr/sbin
$ run-as-cron 'echo $PATH'
/usr/bin:/bin
$ 
```
You can see that `bash` from the command line is looking in a lot more places to find something that matches the command you just typed in than `sh` run by cron does.

And that is at the heart of a lot of problems people experience.

## TROUBLESHOOTING CRON JOBS

Once you have run-as-cron installed, you are on your way to figuring out what is going on. One recent issue I ran into was related to use of `sendmail`. When I would run a script from the normal command prompt things worked fine, but when this same command was run as a cron job it would not mail the file.

The `where` command is a quick way to find the subdirectory a particular command is located in. I ran the following commands and the problem became clear.
```
$ which sendmail
/sbin/sendmail
$ run-as-cron 'which sendmail'
which sendmail
/bin/sh: 1: which sendmail: not found
$ 
```
On my system, `sendmail` is in the `/sbin/sendmail` subdirectory--a directory cron does not access. So when I try to run `sendmail` as part of a script started by cron, it may fail like this:
```
$ echo "Subject: sendmail test" | sendmail -v jim30109@gmail.com
...
_Lots of good stuff here!!!_
...
$ run-as-cron 'echo "Subject: sendmail test" | sendmail -v jim30109@gmail.com'
/bin/sh: 1: echo "Subject: sendmail test" | sendmail -v jim30109@gmail.com: not found
$
```
Since `which` told me where to find `sendmail`, I know that I need to use `/sbin/sendmail` instead of just `sendmail` to make things work:
```
$ run-as-cron 'echo "Subject: sendmail test" | /sbin/sendmail -v jim30109@gmail.com'
...
_Lots of good stuff here!!!_
...
$
```
So, as expected, all that was needed to resolve the issue was putting the full path for the command that seemed to 'fail' (or not be executed) when running as a cron job.

## REFERENCES

I have seen similar scripts around, but the two sources I used when I decided it was time to put this tool together were [Marco's answer out on serverfault.com](https://serverfault.com/questions/85893/running-a-cron-job-manually-and-immediately) and [Micheal Barton's answer (with edits by Matyas) out on stackexchange.com](https://unix.stackexchange.com/questions/42715/how-can-i-make-cron-run-a-job-right-now-for-testing-debugging-without-changing).

## THE FINE PRINT

This is simply a compilation of items I've pulled from various public sources and tweaked a bit. I do not believe any of the material used as reference was copyrighted. But if there are any previous copyright claims on anything similar, this particular implementation is an original work and reference to previous works would fall into the category of Fair Use.

This README.md file and the detailed installation instruction are original works by Jim McClanahan W4JBM.

This is released under the unlicense.

This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or distribute this software, either in source code form or as a compiled binary, for any purpose, commercial or non-commercial, and by any means.

In jurisdictions that recognize copyright laws, the author or authors of this software dedicate any and all copyright interest in the software to the public domain. We make this dedication for the benefit of the public at large and to the detriment of our heirs and successors. We intend this dedication to be an overt act of relinquishment in perpetuity of all present and future rights to this software under copyright law.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

For more information, please refer to <http://unlicense.org/>
