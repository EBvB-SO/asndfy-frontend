//
//  LegalAndPrivacyView.swift
//  Ascendify
//
//  Created by Ellis Barker on 10/02/2025.
//

import SwiftUI

struct LegalAndPrivacyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Privacy & Data Policy")
                    .font(.title)
                    .bold()
                
                Text("""
This app (Ascendify) collects personal information such as climbing history, strengths, weaknesses and other training data through a questionnaire. These details are used solely for generating individualised climbing training plans.

• **Data Use**: Your data is processed locally and sent to our secure server (and the OpenAI API) to generate the customised plan.  
• **Data Storage**: We store your profile data only as needed for the app’s functionality and do not share it with unauthorised third parties.  
• **GDPR Compliance**: If you are located in the EU or UK, you have the right to access, rectify, or request deletion of your personal data at any time. Contact us at [info@ascendify.co.uk](mailto:infot@ascendify.co.uk) to exercise these rights.  
• **Data Retention**: We retain your training profile for as long as you use the app or until you request deletion.
• **Third-Party Services**: We use OpenAI’s API to generate training plans. By using this app, you understand that some information may be processed by OpenAI's servers.  

""")
                .foregroundColor(.primary)

                Text("Disclaimer of Medical Advice")
                    .font(.title2)
                    .bold()
                
                Text("""
Ascendify provides general training guidance for climbing. We are not medical professionals and this content is not intended to be a substitute for professional medical advice, diagnosis or treatment. Always seek the advice of a qualified health provider before beginning any climbing or exercise program.

• **Climbing Risks**: Rock climbing and training for it involves inherent risks. You agree to assume all responsibility for any injuries or harm arising from participation in training.  
• **No Guarantees**: We do not guarantee specific outcomes from following these plans.  
""")
                .foregroundColor(.primary)

                Text("Liability & Waiver")
                    .font(.title2)
                    .bold()
                
                Text("""
By using Ascendify, you acknowledge that climbing is a high-risk activity and that no training plan can eliminate risks. You agree to hold Ascendify, its developers and partners harmless from any liability or claims arising from injuries or other damages resulting from use of this app.

If you do not agree to these terms, please discontinue use of Ascendify.
""")
                .foregroundColor(.primary)
                .padding(.bottom, 20)
            }
            .padding()
        }
        .navigationTitle("Legal & Privacy")
    }
}

struct LegalAndPrivacyView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            LegalAndPrivacyView()
        }
    }
}
