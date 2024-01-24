*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${True}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.JavaAccessBridge
Library             RPA.PDF
Library             RPA.Archive
Library             OperatingSystem
Library             RPA.FileSystem
Library             RPA.Assistant


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    User input task
    # Open the robot order website
    Download CSV file
    Process all orders
    Create ZIP package from PDF files
    [Teardown]    Close the browser


*** Keywords ***
Open the robot order website
    # https://robotsparebinindustries.com/#/robot-order
    [Arguments]    ${url}
    Open Available Browser    ${url}
    Maximize Browser Window

Download CSV file
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True

Process all orders
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Submit the order    ${row}
    END

Close the annoying modal
    Wait And Click Button    css:button.btn-dark

Get orders
    ${table}=    Read table from CSV    orders.csv    header=${True}    delimiters=","
    RETURN    ${table}

Fill the form
    [Arguments]    ${row}
    Select From List By Value    id:head    ${row}[Head]
    Wait Until Element Is Visible    css:div.radio
    Select Radio Button    body    value=${row}[Body]
    Input Text    css:input.form-control    ${row}[Legs]
    Input Text    id:address    ${row}[Address]
    Click Button    id:preview

Save Screenshot
    ${screenshot}=    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}robot_preview.png

Click order button
    Click Element When Clickable    id:order
    Element Should Not Be Visible    css:div.alert-danger

Submit the order
    [Arguments]    ${row}
    Wait Until Keyword Succeeds    5 times    0.5 s    Click order button
    Wait Until Element Is Visible    id:order-completion
    ${screenshot}=    Save Screenshot
    ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
    Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}    ${row}

Store the receipt as a PDF file
    [Arguments]    ${row}
    Wait Until Element Is Visible    id:order-completion
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    ${pdf}=    Html To Pdf    ${receipt_html}    ${OUTPUT_DIR}${/}receipt.pdf

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}    ${row}
    ${files}=    Create List
    ...    ${OUTPUT_DIR}${/}receipt.pdf
    ...    ${OUTPUT_DIR}${/}robot_preview.png
    OperatingSystem.Create Directory    ${CURDIR}${/}pdfs
    Add Files To Pdf    ${files}    ${CURDIR}${/}pdfs${/}final_receipt_${row}[Order number].pdf
    Click Element When Clickable    id:order-another

Create ZIP package from PDF files
    # @{files}=    OperatingSystem.List Files In Directory    ${CURDIR}${/}pdfs    final*.pdf
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/PDFs.zip
    Archive Folder With Zip
    ...    ${CURDIR}${/}pdfs
    ...    ${zip_file_name}

Close the browser
    Close Browser

User input task
    Add Heading    Input from User
    Add Text Input    text_input    Please enter URL
    Add Submit Buttons    buttons=Submit,Cancel    default=Submit
    ${result}=    Run Dialog

    ${url}=    Set Variable    ${result}[text_input]
    Log To Console    ${url}
    Open the robot order website    ${url}
