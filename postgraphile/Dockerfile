FROM node:alpine

RUN npm i -g postgraphile

CMD postgraphile -n 0.0.0.0 -c postgres://$USER:$PASS@$HOST:$PORT/$DB --default-role $ANON --schema $SCHEMA --watch --secret $SECRET--token $SCHEMA.$JWT