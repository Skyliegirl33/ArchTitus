#!/bin/bash

export PATH=$PATH:~/.local/bin
cp -r $HOME/QuackOS/dotfiles/* $HOME/.config/
pip install konsave
konsave -i $HOME/QuackOS/quackos.knsv
sleep 1
konsave -a quackos
