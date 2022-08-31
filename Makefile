# Dummy makefile, will call the host and enclave makefile when requested.

SRC_U = app
SRC_T = enclave

CUSTOM_EDL_PATH != realpath 'sgx-sdk/edl'
CUSTOM_COMMON_PATH != realpath 'sgx-sdk/common'
XARGO_PATH != realpath 'sgx-sdk/xargo'
ENCLAVE_METADATA = enclave/enclave.meta.txt

export CUSTOM_EDL_PATH CUSTOM_COMMON_PATH XARGO_PATH


ifeq "$(SGX_MODE)" "HW"
    POLICY_ALLOW_DEBUG ?= "false"
else
    POLICY_ALLOW_DEBUG ?= "true"
endif

# Compilation process, will call the appropriate makefiles.

all: host enclave

init: check-and-reinit-submodules

$(ENCLAVE_METADATA): enclave

check-and-reinit-submodules:
	@if git submodule status | egrep -q '^[-]|^[+]' ; then \
		echo "INFO: Need to reinitialize git submodules"; \
		git submodule update --init; \
	fi

host:
	@echo "\033[32mRequest to compile the host part...\033[0m"
	@make -C $(SRC_U)

enclave: init
	@echo "\033[32mRequest to compile the enclave part...\033[0m"
	@make -C $(SRC_T)

clean: clean_client
	@make -C $(SRC_U) clean
	@make -C $(SRC_T) clean

fclean:
	@make -C $(SRC_U) fclean
	@make -C $(SRC_T) fclean

clean_host:
	@make -C $(SRC_U) clean

clean_enclave:
	@make -C $(SRC_T) clean

fclean_host:
	@make -C $(SRC_U) fclean

fclean_enclave:
	@make -C $(SRC_T) fclean

re_host: fclean_host host

re_enclave: fclean_enclave enclave

re: fclean all

# Dummy rules to let make know that those rules are not files.

.PHONY: init check-and-reinit-submodules host enclave client clean clean_host clean_enclave clean_client fclean_host fclean_enclave fclean re re_host re_enclave