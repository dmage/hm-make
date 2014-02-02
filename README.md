## Home files Manager v2
Second version of home files manager

## Usage

    git clone https://github.com/dmage/hm-make ~/hm-make
    cd ~/hm-make
    make

    mkdir ~/.hm
    git clone https://github.com/dmage/dmage-hm-repo ~/.hm/dmage-hm-repo
    cd ~/.hm/dmage-hm-repo
    git submodule update --init --remote
    git submodule foreach git checkout master

    ~/hm-make/hm-make -v ~/.hm/dmage-hm-repo/meta-workstation
