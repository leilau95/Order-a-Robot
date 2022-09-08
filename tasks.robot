*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${True}
Library             RPA.HTTP
Library             RPA.Excel.Files
Library             RPA.Tables
Library             RPA.Robocorp.Vault
Library             OperatingSystem
Library             RPA.PDF
Library             RPA.Dialogs
Library             RPA.Archive


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Read Vault
    Open the robot order website
    ${orders}=    Read orders from csv file
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Wait Until Keyword Succeeds    5x    2s    Submit order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Order another robot
    END
    Create a ZIP file of the receipts


*** Keywords ***
Read Vault
    ${vault}=    Get Secret    variables
    Set Global Variable    ${variables}    ${vault}

Open the robot order website
    Open Available Browser    ${variables}[URL]

Close the annoying modal
    Click Button    class:btn.btn-dark

Read orders from csv file
    ${csvfile}=    Input form dialog
    Download    ${csvfile}    overwrite=True
    ${orders}=    Read table from CSV    orders.csv
    RETURN    ${orders}

Fill the form
    [Arguments]    ${order}
    Select From List By Value    id:head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    //input[@placeholder='Enter the part number for the legs']    ${order}[Legs]
    Input Text    id:address    ${order}[Address]

Preview the robot
    Click Button    id:preview
    Wait Until Element Is Visible    id:robot-preview-image

Submit order
    Click Button    id:order
    Wait Until Element Is Visible    id:receipt

Store the receipt as a PDF file
    [Arguments]    ${ordernumber}
    ${receipt_element}=    Get Element Attribute    //*[@id="receipt"]    outerHTML
    Set Local Variable    ${savepath}    ${CURDIR}${/}output${/}receipts${/}${ordernumber}.pdf
    Html To Pdf    content=${receipt_element}    output_path=${savepath}
    RETURN    ${savepath}

Take a screenshot of the robot
    [Arguments]    ${ordernumber}
    Set Local Variable    ${savepath}    ${CURDIR}${/}output${/}images${/}${ordernumber}.png
    Capture Element Screenshot    id:robot-preview-image    ${savepath}
    RETURN    ${savepath}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${robotimg}    ${receipt}
    ${imagelist}=    Create List    ${robotimg}
    Add Files To Pdf    ${imagelist}    ${receipt}    ${True}

Order another robot
    Click Button    id:order-another

Create a ZIP file of the receipts
    Archive Folder With Zip
    ...    ${CURDIR}${/}output${/}receipts
    ...    ${CURDIR}${/}output${/}receipts.zip
    ...    recursive=true
    ...    include=*.pdf

Input form dialog
    Add heading    Add csv location
    Add text input    csv    label=Input csv
    ${result}=    Run dialog
    log    ${result.csv}
    RETURN    ${result.csv}
