#!/bin/bash -e

if [[ ${#1} -eq 0 ]]; then
    echo
    echo "[ERROR] swagger file not specified"
    exit 1
fi

gen_root=/usr/swagger
sdk_output_folder=$gen_root/projects/lusid-sdk-angular7/src/lib/generated
swagger_file=$gen_root/$1

#   remove all previously generated files
shopt -s extglob 
echo "removing previous sdk:"
rm -rf $sdk_output_folder/
shopt -u extglob 

# ignore files
mkdir -p $sdk_output_folder
cp /usr/src/.swagger-codegen-ignore $sdk_output_folder

echo "generating sdk"

#java -jar swagger-codegen-cli.jar swagger-codegen-cli help
java -jar swagger-codegen-cli.jar generate \
    -i $swagger_file \
    -l typescript-angular \
    -o $sdk_output_folder \
    -c $gen_root/config.json \
    --additional-properties ngVersion=7

rm -rf $sdk_output_folder/.swagger-codegen
rm $sdk_output_folder/.gitignore
rm $sdk_output_folder/.swagger-codegen-ignore
rm $sdk_output_folder/git_push.sh

find $sdk_output_folder -type f | xargs -I £ sed -i 's/rxjs\/Observable/rxjs/g' £

cd $gen_root

sdk_version=$(cat $swagger_file | jq -r '.info.version')-alpha
echo $sdk_version

echo "updating version in package.json to '$sdk_version'"
package_json=$gen_root/projects/lusid-sdk-angular7/package.json
cat $package_json | jq -r --arg SDK_VERSION "$sdk_version" '.version |= $SDK_VERSION' > temp && mv temp $package_json

echo "installing packages"
npm ci

echo "running ng build"
ng build lusid-sdk-angular7