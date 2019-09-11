FROM zokrates/zokrates
COPY ./ ./
ENV args 0
RUN ./zokrates compile -i circuits/transaction.code
RUN ./zokrates setup
CMD ./zokrates compute-witness -a ${args}; ./zokrates generate-proof
