emacs ?= emacs
DIR  = lisp
FILE = $(DIR)/kbd-mode.el

.PHONY: all clean

all: compile

compile:
  $(emacs) -batch -l $(FILE) --eval="(byte-compile-file \"$(FILE)\")"

run:
  $(emacs) -Q -l $(FILE)

clean:
  rm -f $(DIR)/*.elc
