from py934.jubjub import Field
from py934.mimblewimble import Output, TxSend, TxReceive

if __name__ == "__main__":
    value = Field(500)
    fee = Field(10)
    inputs = Output.from_secrets(8780529755356302838835647148138951993159754624309233135435419202761373729957, 10000)
    changes = Output.from_secrets(14902853961173674819632624364155628863264191574535817713917635227095832614123, 9490)
    sender_sig_salt = Field(4120245739117451112346021348787553501225199013107048644923802326328116490937)
    outputs = Output.from_secrets(18551030071869416710885169846917322869724902207203392495128267492931654300281, 500)
    receiver_sig_salt = Field(9742180293582931285883601457719660818964694434137621747019174932659290254601)
    metadata = Field(63106042662321134846374981)
    # metadata = "Ethereum934"
    tx_send = TxSend.builder(). \
        value(value). \
        fee(fee). \
        input_txo(inputs). \
        change_txo(changes). \
        metadata(metadata). \
        sig_salt(sender_sig_salt). \
        build()

    request = tx_send.request

    tx_receive = TxReceive.builder(). \
        request(request). \
        output_txo(outputs). \
        sig_salt(receiver_sig_salt). \
        build()

    response = tx_receive.response

    transaction = tx_send.merge(response)
    print('Kernel', transaction.kernel)
    print('Body', transaction.body)
