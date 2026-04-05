FROM nginx:alpine

WORKDIR /usr/share/nginx/html

# Copy code FE
COPY index.html .

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
