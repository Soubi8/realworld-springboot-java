FROM gradle:7.4-jdk11-alpine AS build
COPY --chown=gradle:gradle . /home/gradle/src
WORKDIR /home/gradle/src
RUN gradle build --no-daemon
FROM openjdk:11.0.10-jre-buster
EXPOSE 8080
RUN mkdir /app
COPY --from=build /home/gradle/src/build/libs/realworld-spring-boot-java-2.1.[0-1].jar /app/realworld-spring-boot-java-2.1.1.jar
ENTRYPOINT ["java","-Xmx64m","-Xms64m","-jar","/app/realworld-spring-boot-java-2.1.1.jar"]