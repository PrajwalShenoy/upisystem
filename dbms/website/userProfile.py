from flask import Blueprint,render_template, request, flash, session, redirect
from .dbConnection import conn

userprofile = Blueprint('userProfile', __name__)
cursor = conn.cursor()

@userprofile.route('/userProfile', methods = ['GET', 'POST'])
def viewUserProfile():
    if 'ssn' not in session.keys():
            flash("Login to a user first", category='error')
            return redirect('/login')
    if request.method == 'POST':
        received_data = dict(request.form)
        if 'bankAccountNumber' in received_data.keys():
            deleteBankAccount(received_data)
    return render_template("userProfile.html",
                            firstName=session['first_name'],
                            lastName=session['last_name'],
                            ssn=session['ssn'],
                            houseNumber=session['house_number'],
                            streetName=session['street_name'],
                            city=session['city'],
                            state=session['state'],
                            pin=session['pin'])

def deleteBankAccount(received_data):
    cursor.execute("SELECT checkIfAccountBelongsToSSN(%s, %s)", (session['ssn'], received_data['bankAccountNumber']))
    all_rows = cursor.fetchall()
    if (not all_rows[0][0]):
        flash("Bank account is not valid", category='error')
        return
    cursor.callproc('deleteBankAccount', (received_data['bankAccountNumber'],))
    flash("Deleted account " + received_data['bankAccountNumber'] + " successfully")


@userprofile.route('/accountDetails', methods = ['GET'])
def bankDetails():
    if 'ssn' not in session.keys():
            flash("Login to a user first", category='error')
            return redirect('/login')
    ssn = session['ssn']
    cursor.callproc("viewAccountDetails", (ssn,))
    for result in cursor.stored_results():
        all_rows=result.fetchall()
    cursor.callproc("viewUPIConsumerDetailsForSSN", (ssn,))
    for result in cursor.stored_results():
        all_rows_consumer = result.fetchall()
    cursor.callproc("viewUPIMerchantDetailsForSSN", (ssn,))
    for result in cursor.stored_results():
        all_rows_merchant = result.fetchall()
    # table = """<table>
    #             <tr>
    #                 <th>Bank Name</th>
    #                 <th>Branch ID</th>
    #                 <th>Bank Account</th>
    #                 <th>Balance</th>
    #                 <th>Building Number</th>
    #                 <th>Street Name</th>
    #                 <th>City</th>
    #                 <th>Pin</th>
    #             </tr>\n"""
    # for i in all_rows:
    #     table += f"""<tr>
    #                 <td>{i[0]}</td>
    #                 <td>{i[1]}</td>
    #                 <td>{i[2]}</td>
    #                 <td>{i[3]}</td>
    #                 <td>{i[4]}</td>
    #                 <td>{i[5]}</td>
    #                 <td>{i[6]}</td>
    #                 <td>{i[7]}</td>
    #             </tr>\n"""
    # table += "</table>"
    # return table
    print(all_rows_consumer)
    print(all_rows_merchant)
    return render_template("userBankDetails.html", length=len(all_rows), table_list=all_rows,
                           consumer_length = len(all_rows_consumer), consumer_table_list = all_rows_consumer,
                           merchant_length = len(all_rows_merchant), merchant_table_list = all_rows_merchant)

