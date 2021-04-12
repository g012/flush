#/bin/sh

mkdir to.pre

cd ..
make clean
make
mv rev_16_gba.gba pre/to.pre
cd pre
cp ./flush_twis.nfo ./to.pre
cp ./FILE_ID.DIZ ./to.pre
cd ./to.pre
zip flush-twis.zip *
cd ../../
make clean
cd pre
mkdir to.deliver
mv to.pre/flush-twis.zip to.deliver
rm -rf to.pre
