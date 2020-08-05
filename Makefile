CXX         = clang++
NONWARNINGS = -Wno-c++98-compat -Wno-padded -Wno-missing-prototypes -Wno-dangling-else -Wno-old-style-cast -Wno-unused-macros -Wno-comma
WARNINGS    = -Wall -Wextra -Wparentheses -pedantic-errors -Weverything -Werror $(NONWARNINGS)
# -stdlib=libc++
STDLIB      =
# -lstdc++ -lc++abi
LDFLAGS     =
CXX_VERSION = c++20
ifeq ($(SANS),)
ifeq ($(FAST),)
	SANITIZER=
	OPTIMIZATION=-O3
	LOPTIMIZATION=-s -flto
else
	SANITIZER=
	OPTIMIZATION=-O0
	LOPTIMIZATION=
endif
else
	SANITIZER=-fsanitize=$(SANS)
	OPTIMIZATION=-O0 -g -ftrapv
	LOPTIMIZATION=
endif
OPTFLAGS    = $(SANITIZER) $(OPTIMIZATION)
CXXFLAGS    = -std=$(CXX_VERSION) $(STDLIB) $(WARNINGS) $(OPTFLAGS) -Wfatal-errors
LINKFLAGS   = $(LDFLAGS) $(STDLIB) $(SANITIZER) $(LOPTIMIZATION)

.PHONY:all seg mseg asan msan
all: format TAGS deps mains
seg: clean asan
mseg: clean msan
#Current sanitizers are undefined, address, thread, and memory.
asan:
	make --no-print-directory all SANS=address
msan:
	make --no-print-directory all SANS=memory

# generate the etags file
TAGS:
	@rm -f TAGS
	@git ls-files|grep "pp$$"|xargs -r etags -a --declarations
	@echo "Generated Tags"

# use the etags file to find all excicutables
.PHONY:mains
mains:
	@for f in `ls *.cpp` ; do \
		if etags $$f -o - | grep "int main(" - > /dev/null; \
			then echo $$f | sed -e 's/[.][^.]*$$/.bin/' -e 's/.*/make --no-print-directory &/' |sh; \
		fi ; \
	done

.PHONY:deps
deps:
	-@for f in `ls *.cpp` ; do \
		echo $$f | sed -e 's,cpp$$,d,' -e 's/.*/make -s .d\/&/'|sh; \
	done

# dependancy making
DEPDIR      = .d
$(shell mkdir -p $(DEPDIR) > /dev/null)
.PRECIOUS: $(DEPDIR)/%.d
$(DEPDIR)/%.d: %.cpp
	@set -e; rm -f $@; \
	 $(CXX) -MM $(CXXFLAGS) $< > $@.$$$$; \
	 echo ".INTERMEDIATE: $*.o" >> $@; \
	 sed 's,\($*\)\.o[ :]*,\1.o $@ : ,g' < $@.$$$$ >> $@; \
	 sed -e 's,[.]o\([ :]\),.bin\1,g' -e 's,[.][hc]pp\>,.o,g' -e 's,\<[a-zA-Z]*[.]tpp\>,,g' < $@.$$$$ >> $@; \
	 printf '\t$$(CXX) $$(LINKFLAGS) -o $$@ $$^' >> $@; \
	 echo >> $@; \
	 rm -f $@.$$$$
	@echo "remade $@"

# emacs flycheck-mode
.PHONY:check-syntax csyntax
check-syntax: csyntax
csyntax:
	$(CXX) $(CXXFLAGS) -c ${CHK_SOURCES} -o /dev/null

.PHONY: clean
clean:
	rm -rf -- *.o *.bin .d/

# Remake using find's features to filter and run
.PHONY: format
format:
	@find|egrep '.*[.](cpp|hpp|cxx|hxx|cc|hc|c++|h++|c|h|tpp|txx)$$'|sed 's/[] ()'\''\\[&;]/\\&/g'|xargs clang-format -i
	@echo "reformatted code"

.PHONY: spell
spell:
	@echo " - Searching for Non-words in Code files -"
	@git ls | cut -f 2 | egrep "[.][ch](pp|)$$" | \
	 while read f; do \
		w=`cat $$f | aspell list --camel-case | sort | uniq | awk '{ if(length($$1)>4)print $$1 } '` ; \
		[ -z "$$w" ] || echo "$$f :: $$w" | xargs ; \
	 done

# This should be remade into a clang tool that removes strings
.PHONY: histogram
histogram:
	@echo " - Building a histogram of used words - "
	@git ls | cut -f 2 | egrep "[.][ch](pp|)$$" | \
	 while read f; do cat $$f; done | \
	 sed 's/\(\s\|[]({,<=>;})[*/+-]\|[0-9]\)/\n/g'|grep -v "^$$"|\
	 sort|uniq -c|sort -gr|head

.PHONY: wet_detector
wet_detector:
	@echo " - Looking for WET lines - "
	@find|egrep "[.]c$"|xargs cat|egrep "[[:alnum:]]"|\
         sed -e 's,^\([[:space:]]\|[{}]\)*,,' -e 's,\([[:space:]]\|[{}]\)*$,,'|\
         egrep -vxf <(echo "break;\nelse\nreturn.*;\n#.*\n//.*\ndefault:")|\
         sort|uniq -c|grep -v "^[[:blank:]]*[1-4] " |sort -rn|head

include $(wildcard $(DEPDIR)/*.d)
include $(wildcard *.d)
