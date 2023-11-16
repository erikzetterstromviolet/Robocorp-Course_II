*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library    RPA.HTTP
Library    RPA.Tables
Library    RPA.Browser.Selenium    auto_close=${False}
Library    RPA.PDF
Library    RPA.Archive
Library    RPA.FileSystem

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${orders}=    Retrieve order file
    Go to order page
    Complete orders    ${orders}

*** Keywords ***
Retrieve order file
    Download    https://robotsparebinindustries.com/orders.csv
    ${order_table}=    Read table from CSV    orders.csv
    RETURN    ${order_table}

Go to order page
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Close annoying thing
    Click Button When Visible    class:btn-dark

Complete orders
    [Arguments]    ${orders}
    ${counter}=    Set Variable    ${1}
    FOR    ${order}    IN    @{orders}
        Close annoying thing
        Fill in order into form    ${order}
        Wait Until Keyword Succeeds    100 times    0.2 sec    Press order button
        ${creenshot_path}=    Take a screenshot of the robot    ${counter}
        Save receipt    ${counter}    ${creenshot_path}
        Click order another

        ${counter}    Set Variable    ${counter+1}
    END

    Close Browser
    ${receipt_pdfs_folder}=    Set Variable    ${OUTPUT_DIR}${/}receipts
    Archive Folder With Zip    ${receipt_pdfs_folder}    ${OUTPUT_DIR}${/}receipts_archive.zip
    Clean up files    ${receipt_pdfs_folder}

Fill in order into form
    [Arguments]    ${order}
    Select From List By Value    head    ${order}[Head]
    Select Radio Button    body    ${order}[Head]
    Input Text    xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${order}[Legs]
    Input Text    address    ${order}[Address]

Press order button 
    Click Button When Visible    order
    Is Element Visible    receipt    missing_ok=${False}

Take a screenshot of the robot
    [Arguments]    ${robot_number}
    ${screenshot_path}=    Set Variable    ${OUTPUT_DIR}${/}screenshot_${robot_number}.png
    #Wait Until Element Is Visible    robot-preview-image # Did not work as expected, using sleep instead.
    Sleep    0.5 sec
    Screenshot    robot-preview-image    ${screenshot_path}
    RETURN    ${screenshot_path}

Save receipt 
    [Arguments]    ${robot_number}    ${screenshot_path}
    ${receipt_path}=    Set Variable    ${OUTPUT_DIR}${/}receipts${/}receipt_${robot_number}.pdf
    @{screenshot_list}=    Create List    ${screenshot_path}
    ${receipt_as_html}=    Get Element Attribute    receipt    outerHTML
    Html To Pdf    ${receipt_as_html}    ${receipt_path}
    Open Pdf    ${receipt_path}
    Add Files To Pdf    ${screenshot_list}    ${receipt_path}    ${True}
    Close Pdf    ${receipt_path}

Click order another
    Click Button When Visible    order-another

Clean up files
    [Arguments]    ${receipt_folder_path}
    Remove Directory    ${receipt_folder_path}    recursive=${True}
    @{list_of_files}=    List Files In Directory    ${OUTPUT_DIR}

    FOR    ${file}    IN    @{list_of_files}
        Log    ${file}
        IF    "${file}".split('/')[-1].startswith('screenshot_') and "${file}".split('/')[-1].endswith('.png')
            Remove File    ${file}
        END
    END

    Remove File    orders.csv