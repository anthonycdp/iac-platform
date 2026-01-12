# =============================================================================
# OPA Policy: Security Group Rules
# =============================================================================
# Enforces security group best practices.

package terraform.security

import input as tfplan

# Default deny
default allow := false

# Allow if all security group rules pass
allow if {
    no_ssh_from_internet
    no_rdp_from_internet
    no_wide_open_ports
    restricted_ingress
}

# Deny SSH (port 22) from internet
no_ssh_from_internet if {
    every sg in security_groups {
        every rule in sg.change.after.ingress {
            not rule.from_port == 22
            or not cidr_is_public(rule.cidr_blocks)
        }
    }
}

# Deny RDP (port 3389) from internet
no_rdp_from_internet if {
    every sg in security_groups {
        every rule in sg.change.after.ingress {
            not rule.from_port == 3389
            or not cidr_is_public(rule.cidr_blocks)
        }
    }
}

# Check for wide open ports (0.0.0.0/0 on all ports)
no_wide_open_ports if {
    every sg in security_groups {
        every rule in sg.change.after.ingress {
            not (rule.cidr_blocks[_] == "0.0.0.0/0" and rule.from_port == 0 and rule.to_port == 65535)
        }
    }
}

# Restrict ingress rules
restricted_ingress if {
    every sg in security_groups {
        count(sg.change.after.ingress) < 50  # Limit number of rules
    }
}

# Check if CIDR is public
cidr_is_public(cidr_blocks) if {
    some cidr in cidr_blocks
    cidr == "0.0.0.0/0"
}

# Get all security groups
security_groups[sg] {
    some sg in tfplan.resource_changes
    sg.type == "aws_security_group"
    "create" in sg.change.actions or "update" in sg.change.actions
}

# Violation messages
violation[msg] {
    not no_ssh_from_internet
    msg := "SSH (port 22) should not be accessible from the internet"
}

violation[msg] {
    not no_rdp_from_internet
    msg := "RDP (port 3389) should not be accessible from the internet"
}

violation[msg] {
    not no_wide_open_ports
    msg := "Security groups should not allow all traffic (0.0.0.0/0 on all ports)"
}
