#!/usr/bin/env sh
set -e

GRAAL_VERSION="1.0.0-rc6-graal"

echo " ==== REQUIREMENTS ==== "
# sdk use java 1.0.0-rc6-graal
echo " $ sdk use java $GRAAL_VERSION "
echo "And add this bash alias to your profile ... "
# alias native-image="$HOME/.sdkman/candidates/java/1.0.0-rc6-graal/bin/native-image"
echo "  alias native-image=\"$HOME/.sdkman/candidates/java/1.0.0-rc6-graal/bin/native-image\" "
echo "========================"



java -version
native-image --version

GRAALVM_HOME="$HOME/.sdkman/candidates/java/$GRAAL_VERSION"

MAIN_CLASS_NAME="com.bastman.kubesecret.App"
COMPILER_SINK_FILE="build/kubesecret.darwin-amd64"
GRADLE_COMMAND="./gradlew clean shadowJar"
GRADLE_SINK_JAR="./build/libs/kotlin-graalvm-example-1.0-SNAPSHOT-all.jar"

#OPTS=""
OPTS="-O0 --verbose -H:+ReportUnsupportedElementsAtRuntime -H:ReflectionConfigurationFiles=./graalvm-reflection.json"
#OPTS="-H:ReflectionConfigurationFiles=./reflection.json -H:+ReportUnsupportedElementsAtRuntime -Dfile.encoding=UTF-8"
#-H:PrintFlags=Expert
#  --expert-options
#OPTS="-H:+ReportUnsupportedElementsAtRuntime -Dfile.encoding=UTF-8"

#DELAY_STATIC_TO_RUNTIME=""
DELAY_STATIC_TO_RUNTIME="--delay-class-initialization-to-runtime=shadow.kotlin.reflect.jvm.internal.impl.builtins.SuspendFunctionTypesKt"
COMPILER_COMMAND="--verbose -cp ${GRADLE_SINK_JAR} -H:Name=${COMPILER_SINK_FILE} -H:Class=${MAIN_CLASS_NAME} ${OPTS} ${DELAY_STATIC_TO_RUNTIME}"


echo "===== build & compile to native binary .... ===="
echo ""
echo " STEP: build jar ... -> ${GRADLE_SINK_JAR}"
echo ""
echo " sink:"
echo "   - jar: ${GRADLE_SINK_JAR}"
echo " processor:"
echo "   - command: ${GRADLE_COMMAND}"
echo ""
echo " STEP: compile to native binary ... ${GRADLE_SINK_JAR} -> ${COMPILER_SINK_FILE}"
echo ""
echo " source:"
echo "   - jar: ${GRADLE_SINK_JAR}"
echo " sink:"
echo "   - binary file: ${COMPILER_SINK_FILE}"
echo "   - main class name: ${MAIN_CLASS_NAME}"
echo " processor:"
echo "   - graalvm home: $GRAALVM_HOME"
echo " "
echo "============================================="


# gradle build jar
set -ex
${GRADLE_COMMAND}

# compile to native binary
native-image ${COMPILER_COMMAND}

set -e +x

# test the stuff
./${COMPILER_SINK_FILE} --help
./${COMPILER_SINK_FILE} list --help
./${COMPILER_SINK_FILE} get --help
./${COMPILER_SINK_FILE} base64-encode --help
./${COMPILER_SINK_FILE} base64-decode --help
cat ./example-secrets/secret-plain.yaml | ./${COMPILER_SINK_FILE} base64-encode
cat ./example-secrets/secret.yaml | ./${COMPILER_SINK_FILE} base64-decode

echo ""
echo "Done."
echo "You may want to run your compiled binary ..."
echo ""
echo "Usage Examples"
echo ""
echo "$ ./${COMPILER_SINK_FILE}"
echo ""
echo "# requires kubectl"
echo "$ ./${COMPILER_SINK_FILE} list"
echo "$ ./${COMPILER_SINK_FILE} get <YOUR_K8S_SECRET> --base64-decode"
echo ""
echo "# without kubectl"
echo "$ cat example-secrets/secret-plain.yaml | ./${COMPILER_SINK_FILE} base64-encode"
echo "$ cat example-secrets/secret.yaml | ./${COMPILER_SINK_FILE} base64-decode"
echo ""

${COMPILER_SINK_FILE} --help
