// Common definitions for the generated quantities block

// -- Log likelihood, residual deviance, fitted values --
vector[ni_ipd + ni_agd_arm + ns_agd_contrast] log_lik;
vector[ni_ipd + ni_agd_arm + ns_agd_contrast] resdev;
vector[ni_ipd + ni_agd_arm + ni_agd_contrast] fitted;

// -- Estimate integration error --
vector[(ni_agd_arm + ni_agd_contrast) * n_int_thin] theta_bar_cum;

// -- RE shrunken estimate delta --
// Note: These are the individual-level trial-specific treatment effects
vector[RE ? narm_ipd + ni_agd_arm + ni_agd_contrast : 0] delta;

if (RE) {
  for (i in 1:(narm_ipd + ni_agd_arm + ni_agd_contrast)) {
    delta[i] = (trt[i] > 1 ? d[trt[i] - 1] : 0) + (which_RE[i] ? f_delta[which_RE[i]] : 0);
  }
  for (i in 1:ni_agd_contrast) {
    if (agd_contrast_trt_b[i] > 1)
      delta[narm_ipd + ni_agd_arm + i] -= d[agd_contrast_trt_b[i] - 1];
  }
}

// Integration error for AgD
for (i in 1:ni_agd_arm) {
  for (j in 1:n_int_thin) {
    theta_bar_cum[(i-1)*n_int_thin + j] = mean(theta_agd_arm_ii[(1 + (i-1)*nint):((i-1)*nint + j*int_thin)]);
  }
}

for (i in 1:ni_agd_contrast) {
  for (j in 1:n_int_thin) {
    theta_bar_cum[ni_agd_arm + (i-1)*n_int_thin + j] = mean(eta_agd_contrast_ii[(1 + (i-1)*nint):((i-1)*nint + j*int_thin)]);
  }
  // Fitted values
  fitted[ni_ipd + ni_agd_arm + i] = eta_agd_contrast_bar[i];
}

// log likelihood, residual deviance for contrast-based AgD are *per study*
{
  int a = 0;
  int nc;
  for (s in 1:ns_agd_contrast) {
    nc = nc_agd_contrast[s];
    log_lik[ni_ipd + ni_agd_arm + s] = multi_normal_lpdf(agd_contrast_y[(a + 1):(a + nc)] |
      eta_agd_contrast_bar[(a + 1):(a + nc)], agd_contrast_Sigma[(a + 1):(a + nc), (a + 1):(a + nc)]);
    resdev[ni_ipd + ni_agd_arm + s] = quad_form(inv_Sigma[(a + 1):(a + nc), (a + 1):(a + nc)],
                                                agd_contrast_y[(a + 1):(a + nc)] - eta_agd_contrast_bar[(a + 1):(a + nc)]);
    a += nc;
  }
}

