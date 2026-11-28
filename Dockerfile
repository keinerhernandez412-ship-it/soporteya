# ---------- Etapa 1: compilar con el JDK y Maven ----------
FROM eclipse-temurin:21-jdk AS compilacion
WORKDIR /app

# Primero solo lo necesario para descargar dependencias: Docker reutiliza esta capa
# mientras el pom.xml no cambie, y las siguientes compilaciones son mucho más rápidas.
COPY .mvn/ .mvn/
COPY mvnw pom.xml ./
RUN chmod +x mvnw && ./mvnw -q dependency:go-offline

COPY src/ src/
RUN ./mvnw -q -DskipTests package

# ---------- Etapa 2: ejecutar solo con el JRE (imagen más pequeña) ----------
FROM eclipse-temurin:21-jre
WORKDIR /app

# No correr como root dentro del contenedor
RUN useradd --system --uid 1001 soporteya
COPY --from=compilacion /app/target/*.jar app.jar
USER soporteya

ENV SPRING_PROFILES_ACTIVE=prod
EXPOSE 8080
# MaxRAMPercentage: la JVM se ajusta a la memoria del contenedor (512 MB en planes gratuitos)
ENTRYPOINT ["java", "-XX:MaxRAMPercentage=75", "-jar", "app.jar"]