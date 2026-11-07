FROM nginx:alpine

# Remove default nginx configs
RUN rm -rf /etc/nginx/conf.d/* && \
    chown -R 10001:10001 /var/cache/nginx /var/log/nginx /etc/nginx && \
    chmod -R 755 /var/cache/nginx /var/log/nginx

COPY nginx.conf /etc/nginx/nginx.conf
COPY index.html /usr/share/nginx/html/index.html

RUN chown -R 10001:10001 /usr/share/nginx/html && \
    chmod -R 755 /usr/share/nginx/html

# Run as non-root
USER 10001:10001

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]

