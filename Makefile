#
# Assumptions:
#   - Emacs is in `$PATH'
#

DIR  = lisp
FILE = $(DIR)/kbd-mode.el

.PHONY: all clean

all: compile

compile:
	emacs --batch --load=$(FILE) --eval="(byte-compile-file \"$(FILE)\")"

run:
	emacs -Q --load=$(FILE)

clean:
	rm -f $(DIR)/*.elc
