CREATE DATABASE hospital_management_data;
USE hospital_management_data;

-- EDA --
-- Row counts across all tables --
SELECT 'patients_clean'     AS table_name, COUNT(*) AS row_count FROM patients_clean
UNION ALL
SELECT 'doctors',     COUNT(*) FROM doctors
UNION ALL
SELECT 'appointments',COUNT(*) FROM appointments
UNION ALL
SELECT 'treatments',  COUNT(*) FROM treatments
UNION ALL
SELECT 'billing',     COUNT(*) FROM billing;

-- Patient gender distribution
SELECT
    gender,
    COUNT(*)                                     AS patient_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS pct
FROM patients_clean
GROUP BY gender;

-- Patient age group breakdown
SELECT
    age_group,
    COUNT(*)                                     AS patient_count,
    ROUND(MIN(age), 0)                           AS min_age,
    ROUND(MAX(age), 0)                           AS max_age,
    ROUND(AVG(age), 1)                           AS avg_age
FROM patients_clean
GROUP BY age_group
ORDER BY avg_age;

-- Appointment status distribution
SELECT
    status,
    COUNT(*)                                     AS total,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS pct
FROM appointments
GROUP BY status
ORDER BY total DESC;

-- Appointment reasons breakdown
SELECT
    reason_for_visit,
    COUNT(*) AS total
FROM appointments
GROUP BY reason_for_visit
ORDER BY total DESC;

-- Treatment type frequency and cost summary
SELECT
    treatment_type,
    COUNT(*)                    AS treatment_count,
    ROUND(MIN(cost), 2)         AS min_cost,
    ROUND(MAX(cost), 2)         AS max_cost,
    ROUND(AVG(cost), 2)         AS avg_cost,
    ROUND(SUM(cost), 2)         AS total_cost
FROM treatments
GROUP BY treatment_type
ORDER BY total_cost DESC;

-- Overall revenue summary (KPI card data)
SELECT
    ROUND(SUM(amount), 2)                        AS total_revenue,
    ROUND(SUM(CASE WHEN payment_status = 'Paid'    THEN amount ELSE 0 END), 2) AS collected,
    ROUND(SUM(CASE WHEN payment_status = 'Pending' THEN amount ELSE 0 END), 2) AS outstanding,
    ROUND(SUM(CASE WHEN payment_status = 'Failed'  THEN amount ELSE 0 END), 2) AS failed,
    ROUND(
        SUM(CASE WHEN payment_status = 'Paid' THEN amount ELSE 0 END) * 100.0
        / SUM(amount), 1
    )                                            AS collection_rate_pct
FROM billing;

-- Revenue by payment status and method
SELECT
    payment_status,
    payment_method,
    COUNT(*)                    AS bill_count,
    ROUND(SUM(amount), 2)       AS total_amount,
    ROUND(AVG(amount), 2)       AS avg_amount
FROM billing
GROUP BY payment_status, payment_method
ORDER BY payment_status, total_amount DESC;

-- Monthly revenue trend (line chart data)
SELECT
    DATE_FORMAT(bill_date, '%Y-%m')             AS month_year,
    COUNT(*)                                    AS bill_count,
    ROUND(SUM(amount), 2)                       AS monthly_revenue,
    ROUND(SUM(CASE WHEN payment_status = 'Paid' THEN amount ELSE 0 END), 2) AS collected,
    ROUND(AVG(amount), 2)                       AS avg_bill
FROM billing
GROUP BY DATE_FORMAT(bill_date, '%Y-%m')
ORDER BY month_year;

-- Revenue by insurance provider
SELECT
    p.insurance_provider,
    COUNT(DISTINCT p.patient_id)                AS patient_count,
    COUNT(b.bill_id)                            AS total_bills,
    ROUND(SUM(b.amount), 2)                     AS total_revenue,
    ROUND(AVG(b.amount), 2)                     AS avg_bill
FROM patients_clean p
JOIN billing b ON p.patient_id = b.patient_id
GROUP BY p.insurance_provider
ORDER BY total_revenue DESC;

-- Revenue by doctor (full name + specialization)
SELECT
    CONCAT(d.first_name, ' ', d.last_name)     AS doctor_name,
    d.specialization,
    d.hospital_branch,
    COUNT(DISTINCT a.appointment_id)            AS total_appointments,
    ROUND(SUM(b.amount), 2)                     AS total_revenue,
    ROUND(AVG(b.amount), 2)                     AS avg_revenue_per_bill
FROM doctors d
JOIN appointments a  ON d.doctor_id   = a.doctor_id
JOIN billing b       ON a.patient_id  = b.patient_id
GROUP BY d.doctor_id, doctor_name, d.specialization, d.hospital_branch
ORDER BY total_revenue DESC;

-- Revenue by specialization
SELECT
    d.specialization,
    COUNT(DISTINCT d.doctor_id)                AS doctor_count,
    COUNT(DISTINCT a.appointment_id)           AS total_appointments,
    ROUND(SUM(b.amount), 2)                    AS total_revenue,
    ROUND(AVG(b.amount), 2)                    AS avg_revenue_per_appt
FROM doctors d
JOIN appointments a ON d.doctor_id  = a.doctor_id
JOIN billing b      ON a.patient_id = b.patient_id
GROUP BY d.specialization
ORDER BY total_revenue DESC;

-- Hospital branch performance comparison
SELECT
    d.hospital_branch,
    COUNT(DISTINCT d.doctor_id)                AS doctor_count,
    COUNT(DISTINCT a.appointment_id)           AS total_appointments,
    COUNT(DISTINCT a.patient_id)               AS unique_patients,
    ROUND(SUM(b.amount), 2)                    AS total_revenue,
    ROUND(
        SUM(CASE WHEN a.status = 'No-show' THEN 1 ELSE 0 END) * 100.0
        / COUNT(a.appointment_id), 1
    )                                          AS no_show_rate_pct
FROM doctors d
JOIN appointments a ON d.doctor_id  = a.doctor_id
JOIN billing b      ON a.patient_id = b.patient_id
GROUP BY d.hospital_branch
ORDER BY total_revenue DESC;

-- No-show rate by doctor (for Power BI table visual)
SELECT
    CONCAT(d.first_name, ' ', d.last_name)     AS doctor_name,
    d.specialization,
    d.hospital_branch,
    COUNT(*)                                   AS total_appointments,
    SUM(CASE WHEN a.status = 'No-show'    THEN 1 ELSE 0 END) AS no_shows,
    SUM(CASE WHEN a.status = 'Completed'  THEN 1 ELSE 0 END) AS completed,
    SUM(CASE WHEN a.status = 'Cancelled'  THEN 1 ELSE 0 END) AS cancelled,
    SUM(CASE WHEN a.status = 'Scheduled'  THEN 1 ELSE 0 END) AS scheduled,
    ROUND(
        SUM(CASE WHEN a.status = 'No-show' THEN 1 ELSE 0 END) * 100.0
        / COUNT(*), 1
    )                                          AS no_show_rate_pct
FROM appointments a
JOIN doctors d ON a.doctor_id = d.doctor_id
GROUP BY d.doctor_id, doctor_name, d.specialization, d.hospital_branch
ORDER BY no_show_rate_pct DESC;

-- Monthly appointment volume by status (line chart)
SELECT
    DATE_FORMAT(appointment_date, '%Y-%m')     AS month_year,
    COUNT(*)                                   AS total_appointments,
    SUM(CASE WHEN status = 'Completed'  THEN 1 ELSE 0 END) AS completed,
    SUM(CASE WHEN status = 'No-show'    THEN 1 ELSE 0 END) AS no_shows,
    SUM(CASE WHEN status = 'Cancelled'  THEN 1 ELSE 0 END) AS cancelled,
    SUM(CASE WHEN status = 'Scheduled'  THEN 1 ELSE 0 END) AS scheduled,
    ROUND(
        SUM(CASE WHEN status = 'No-show' THEN 1 ELSE 0 END) * 100.0
        / COUNT(*), 1
    )                                          AS no_show_rate_pct
FROM appointments
GROUP BY DATE_FORMAT(appointment_date, '%Y-%m')
ORDER BY month_year;

-- No-show rate by reason for visit
SELECT
    reason_for_visit,
    COUNT(*)                                   AS total,
    SUM(CASE WHEN status = 'No-show' THEN 1 ELSE 0 END) AS no_shows,
    ROUND(
        SUM(CASE WHEN status = 'No-show' THEN 1 ELSE 0 END) * 100.0
        / COUNT(*), 1
    )                                          AS no_show_rate_pct
FROM appointments
GROUP BY reason_for_visit
ORDER BY no_show_rate_pct DESC;

-- Patients by age group and gender
SELECT
    age_group,
    gender,
    COUNT(*)                                   AS patient_count,
    ROUND(AVG(age), 1)                         AS avg_age
FROM patients_clean
GROUP BY age_group, gender
ORDER BY age_group, gender;

-- Revenue by patient age group (stacked bar data)
SELECT
    p.age_group,
    p.gender,
    COUNT(DISTINCT p.patient_id)               AS patient_count,
    COUNT(b.bill_id)                           AS total_bills,
    ROUND(SUM(b.amount), 2)                    AS total_spend,
    ROUND(AVG(b.amount), 2)                    AS avg_spend_per_bill
FROM patients_clean p
JOIN billing b ON p.patient_id = b.patient_id
GROUP BY p.age_group, p.gender
ORDER BY total_spend DESC;

-- Top 10 highest-spending patients
SELECT
    p.patient_id,
    CONCAT(p.first_name, ' ', p.last_name)     AS patient_name,
    p.age_group,
    p.insurance_provider,
    COUNT(b.bill_id)                           AS total_bills,
    ROUND(SUM(b.amount), 2)                    AS total_spend
FROM patients_clean p
JOIN billing b ON p.patient_id = b.patient_id
GROUP BY p.patient_id, patient_name, p.age_group, p.insurance_provider
ORDER BY total_spend DESC
LIMIT 10;

-- New patient registrations by month
SELECT
    DATE_FORMAT(registration_date, '%Y-%m')   AS reg_month,
    COUNT(*)                                  AS new_patients
FROM patients_clean
GROUP BY DATE_FORMAT(registration_date, '%Y-%m')
ORDER BY reg_month;

-- Running total revenue over time
SELECT
    DATE_FORMAT(bill_date, '%Y-%m')           AS month_year,
    ROUND(SUM(amount), 2)                     AS monthly_revenue,
    ROUND(
        SUM(SUM(amount)) OVER (ORDER BY DATE_FORMAT(bill_date, '%Y-%m')), 2
    )                                         AS running_total
FROM billing
GROUP BY DATE_FORMAT(bill_date, '%Y-%m')
ORDER BY month_year;

-- Rank doctors by total revenue within each specialization
SELECT
    CONCAT(d.first_name, ' ', d.last_name)    AS doctor_name,
    d.specialization,
    ROUND(SUM(b.amount), 2)                   AS total_revenue,
    RANK() OVER (
        PARTITION BY d.specialization
        ORDER BY SUM(b.amount) DESC
    )                                         AS rank_in_specialization
FROM doctors d
JOIN appointments a ON d.doctor_id  = a.doctor_id
JOIN billing b      ON a.patient_id = b.patient_id
GROUP BY d.doctor_id, doctor_name, d.specialization
ORDER BY d.specialization, rank_in_specialization;

-- Each patient's most recent appointment and its status
SELECT
    p.patient_id,
    CONCAT(p.first_name, ' ', p.last_name)    AS patient_name,
    a.appointment_date                        AS last_visit,
    a.status                                  AS last_status,
    a.reason_for_visit
FROM patients_clean p
JOIN appointments a ON p.patient_id = a.patient_id
WHERE a.appointment_date = (
    SELECT MAX(a2.appointment_date)
    FROM appointments a2
    WHERE a2.patient_id = p.patient_id
)
ORDER BY last_visit DESC;

-- Revenue percentile ranking per patient
SELECT
    patient_id,
    ROUND(total_spend, 2)                     AS total_spend,
    ROUND(
        PERCENT_RANK() OVER (ORDER BY total_spend) * 100, 1
    )                                         AS spend_percentile
FROM (
    SELECT
        patient_id,
        SUM(amount) AS total_spend
    FROM billing
    GROUP BY patient_id
) AS patient_spend
ORDER BY spend_percentile DESC;

-- Month-over-month revenue change
SELECT
    month_year,
    monthly_revenue,
    LAG(monthly_revenue) OVER (ORDER BY month_year) AS prev_month_revenue,
    ROUND(
        (monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY month_year))
        * 100.0
        / NULLIF(LAG(monthly_revenue) OVER (ORDER BY month_year), 0), 1
    )                                               AS mom_change_pct
FROM (
    SELECT
        DATE_FORMAT(bill_date, '%Y-%m')  AS month_year,
        SUM(amount)                      AS monthly_revenue
    FROM billing
    GROUP BY DATE_FORMAT(bill_date, '%Y-%m')
) AS monthly
ORDER BY month_year;

CREATE OR REPLACE VIEW vw_clinic_master AS
SELECT
    -- Appointment
    a.appointment_id,
    a.appointment_date,
    DATE_FORMAT(a.appointment_date, '%Y-%m')   AS month_year,
    MONTHNAME(a.appointment_date)              AS month_name,
    YEAR(a.appointment_date)                   AS appt_year,
    a.reason_for_visit,
    a.status                                   AS appointment_status,

    -- Patient
    p.patient_id,
    CONCAT(p.first_name, ' ', p.last_name)     AS patient_name,
    p.gender,
    p.age,
    p.age_group,
    p.insurance_provider,

    -- Doctor
    d.doctor_id,
    CONCAT(d.first_name, ' ', d.last_name)     AS doctor_name,
    d.specialization,
    d.hospital_branch,
    d.years_experience,

    -- Treatment
    t.treatment_id,
    t.treatment_type,
    t.description                              AS treatment_description,
    t.cost                                     AS treatment_cost,

    -- Billing
    b.bill_id,
    b.amount                                   AS bill_amount,
    b.payment_method,
    b.payment_status

FROM appointments a
JOIN patients_clean   p ON a.patient_id    = p.patient_id
JOIN doctors    d ON a.doctor_id     = d.doctor_id
JOIN treatments t ON a.appointment_id = t.appointment_id
JOIN billing    b ON b.treatment_id  = t.treatment_id;

-- Preview the master view
SELECT * FROM vw_clinic_master LIMIT 10;

-- === DATA QUALITY CHECKS ===
--  Check for orphaned appointments (no matching treatment)
SELECT a.appointment_id
FROM appointments a
LEFT JOIN treatments t ON a.appointment_id = t.appointment_id
WHERE t.treatment_id IS NULL;

-- Check for bills without a matching treatment
SELECT b.bill_id, b.treatment_id
FROM billing b
LEFT JOIN treatments t ON b.treatment_id = t.treatment_id
WHERE t.treatment_id IS NULL;

-- Check for NULL amounts in billing
SELECT COUNT(*) AS null_amount_count
FROM billing
WHERE amount IS NULL;

-- Check for duplicate patient emails
SELECT email, COUNT(*) AS occurrences
FROM patients_clean
GROUP BY email
HAVING COUNT(*) > 1;

-- Verify all bill amounts match their treatment costs
SELECT
    b.bill_id,
    b.amount         AS billed_amount,
    t.cost           AS treatment_cost,
    b.amount - t.cost AS discrepancy
FROM billing b
JOIN treatments t ON b.treatment_id = t.treatment_id
WHERE ROUND(b.amount, 2) <> ROUND(t.cost, 2);

-- 