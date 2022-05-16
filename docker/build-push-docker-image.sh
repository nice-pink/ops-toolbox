#! /bin/sh -
PROGNAME=$0

if [[ -z "$IR_SERVER" || -z "$IR_USER" || -z "$IR_PASS" ]]
then
  echo 'You need to set env vars $IR_SERVER, $IR_USER and $IR_PASS.'
  exit -1
fi

usage() {
  cat << EOF >&2
Usage: $PROGNAME [-i <imagename>] [-v <version>] [-d <dockerfile>] [-t <target>]

-i <imagename>: Specify the docker image name.
-v <version>: Default: latest
-d <dockerfile>: Default: ./Dockerfile
-t <target>: Target of multi-stage dockerfile.
-p <project>: Project in registry. Default: builder

EOF
  exit 1
}

# defaults
unset imagename
unset dockertarget
project=builder
dockerfile=./Dockerfile
version=latest

while getopts i:p:v:d:t: o; do
  case $o in
    (i) imagename=$OPTARG;;
    (p) project=$OPTARG;;
    (v) version=$OPTARG;;
    (d) dockerfile=$OPTARG;;
    (t) dockertarget=$OPTARG;;
    (*) usage
  esac
done
shift "$((OPTIND - 1))"

echo Remaining arguments: "$@"

if [ -z "$imagename" ]; then
        echo 'You have to specify the image name. Set -i parameter' >&2
        exit 1
fi

echo "image name: $imagename"
echo "project: $project"
echo "version: $version"
echo "dockerfile: $dockerfile"
echo "target: $dockertarget"

DOCKER_SERVER=$(echo "$IR_SERVER" | sed 's~http[s]*://~~g')
IMAGE_TAG=$DOCKER_SERVER/$project/$imagename:$version

echo $IR_PASS | docker login $DOCKER_SERVER --username $IR_USER --password-stdin

if [ -z "$dockertarget" ]; then
    docker build -f $dockerfile -t $IMAGE_TAG .
else
    docker build -f $dockerfile --target $dockertarget -t $IMAGE_TAG .
fi

docker push $IMAGE_TAG
