#!/bin/bash

function wake_up() {
  eval `ssh-agent -s`
  /bin/ssh-add ~/.ssh/fruit
}

/bin/ssh-add -l 2&>1
if ! [ $? -eq 0 ]
then
  wake_up;
fi;

/bin/ssh-add -l

exit 0;
