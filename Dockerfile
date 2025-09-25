FROM ubuntu:24.04
LABEL maintainer="support@punctiq.com" \
      org.opencontainers.image.title="Punctiq WEB" \
      org.opencontainers.image.version="1.0.0" \
      org.opencontainers.image.description="Custom Apache2 container with Ubuntu base, user isolation, healthcheck and strict perms" \
      org.opencontainers.image.source="https://www.punctiq.com" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.documentation="https://internal-doc.punctiq.com/"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends apache2 curl \
 && rm -rf /var/lib/apt/lists/*

# Quality-of-life + basic hardening
RUN a2enmod headers rewrite remoteip\
 && echo "ServerName localhost" > /etc/apache2/conf-available/servername.conf \
 && a2enconf servername \
 && sed -i 's/ServerTokens OS/ServerTokens Prod/' /etc/apache2/conf-available/security.conf || true \
 && sed -i 's/ServerSignature On/ServerSignature Off/' /etc/apache2/conf-available/security.conf || true





# Site files
COPY site/ /var/www/html/
COPY apache2/remoteip.conf /etc/apache2/conf-available/remoteip.conf
RUN chown -R www-data:www-data /var/www/html

EXPOSE 80
HEALTHCHECK CMD curl -fsS http://localhost/ || exit 1

# Keep Apache in foreground for Docker
CMD ["apachectl", "-D", "FOREGROUND"]
