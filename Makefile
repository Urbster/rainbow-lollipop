

# src files. ein find . -name *.vala sollte auch gehen
SRC = src/alaia.vala \
      src/tracks.vala \
      src/nodes.vala \
      src/config.vala \

# LIBS werden fuer valac und gcc aufgeloest. VALALIBS und CLIBS
# jeweils nur fuer valac und gcc.
# z.b. valac -pkg libpq  || gcc -lpq
VALALIBS =  
CLIBS = 
LIBS = gtk+-3.0 clutter-1.0 clutter-gtk-1.0 webkitgtk-3.0 gee-1.0

CC = gcc

# Vala compilerflags
VFLAGS = --thread -D DEBUG

# programmname.
TARGET = alaia


######################################################
# haende weg. alles andere wird automatisch gemacht !!
######################################################
 
CFLAGS = $(shell pkg-config --cflags --libs glib-2.0 gobject-2.0)
ifneq ($(LIBS), )
CFLAGS += $(shell pkg-config --cflags --libs $(LIBS))
endif
ifneq ($(CLIBS), )
CFLAGS += $(shell pkg-config --cflags --libs $(CLIBS))
endif

BUILDFOLDER = .build
VAPIFOLDER = $(BUILDFOLDER)/vapifiles
CFOLDER = $(BUILDFOLDER)/cfiles
OFOLDER = $(BUILDFOLDER)/ofiles

#CFILES = $(patsubst %.vala, %.c, $(SRC))
#OBJ = $(patsubst %.vala, %.o, $(SRC))
#VAPIFILES = $(patsubst %.vala, %.vapi, $(SRC))
	

CFILES = $(addprefix $(CFOLDER)/, $(patsubst %.vala, %.c, $(SRC)))
OBJ = $(addprefix $(OFOLDER)/, $(patsubst %.vala, %.o, $(SRC)))
VAPIFILES= $(addprefix $(VAPIFOLDER)/, $(patsubst %.vala, %.vapi, $(SRC)))


MKDIR_P = mkdir -p




FOLDERS = $(VAPIFOLDER) $(CFOLDER) $(OFOLDER)


info:
	@echo "clean - clean"
	@echo "all   - all"

$(FOLDERS):
	$(MKDIR_P) $(FOLDERS)

clean:
	rm -rf $(BUILDFOLDER)
	rm -f $(TARGET)

$(VAPIFOLDER)/%.vapi: %.vala
	@if [ $(@D) != "." ]; then $(MKDIR_P) $(@D); fi
	valac --fast-vapi=$@ $< && touch $@
#       valac --fast-vapi=$*.vapi $*.vala && touch $*.vapi

$(CFOLDER)/%.c: %.vala  
	@if [ $(@D) != "." ]; then $(MKDIR_P) $(@D); fi  
	valac -C $*.vala $(VFLAGS) $(addprefix --use-fast-vapi=, $(patsubst $(VAPIFOLDER)/$(*).vapi, , $(VAPIFILES))) $(addprefix --pkg , $(VALALIBS)) $(addprefix --pkg , $(LIBS)) && mv $*.c $@ && touch $@

$(OFOLDER)/%.o: $(CFOLDER)/%.c
	@if [ $(@D) != "." ]; then $(MKDIR_P) $(@D); fi
	$(CC) $< -c -o $@ $(CFLAGS) && touch $@

$(TARGET): $(FOLDERS) $(VAPIFILES) $(CFILES) $(OBJ)
	$(CC) $(CFLAGS) $(OBJ) -o $(TARGET) && touch $(TARGET)

all: $(TARGET)

